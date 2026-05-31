#!/usr/bin/env uv run
# /// script
# requires-python = ">=3.11"
# dependencies = ["google-genai>=1.33.0", "pyaudio>=0.2.14"]
# ///
"""Run a live, spoken (audio<->audio) conversation with a Gemini Live model.

The model is driven by a system prompt loaded from a file, and is given a small
set of tools that let it read and edit a single output file. Each run creates a
fresh output file inside the given output directory. The tools are sandboxed to
that one file -- they take no path argument, so the model can shape its output
however the prompt directs but cannot touch anything else.

Usage:
    conversation.py <prompt-file> <output-dir>

Requirements:
    - GEMINI_API_KEY must be set in the environment.
    - PyAudio needs PortAudio: `brew install portaudio` (one-time, on macOS).

Talk into your microphone; the model replies through your speakers. Press
Ctrl-C to end the conversation.
"""

import argparse
import asyncio
import sys
import traceback
from datetime import datetime
from pathlib import Path

import pyaudio
from google import genai
from google.genai import types

DEFAULT_MODEL = "gemini-3.1-flash-live-preview"
DEFAULT_VOICE = "Puck"

# Audio format expected by the Live API.
FORMAT = pyaudio.paInt16
CHANNELS = 1
SEND_SAMPLE_RATE = 16000  # microphone -> model
RECEIVE_SAMPLE_RATE = 24000  # model -> speakers
CHUNK_SIZE = 1024


class OutputFile:
    """A single file the model is allowed to read and edit, and nothing else.

    All tools route through this helper, so sandboxing is structural: there is
    no path argument anywhere for the model to manipulate.
    """

    def __init__(self, path: Path):
        self.path = path
        self.path.touch()

    def read_file(self) -> dict:
        return {"result": self.path.read_text()}

    def write_file(self, content: str) -> dict:
        self.path.write_text(content)
        return {"result": f"Wrote {len(content)} characters."}

    def append_file(self, content: str) -> dict:
        with self.path.open("a") as f:
            f.write(content)
        return {"result": f"Appended {len(content)} characters."}

    def replace_in_file(self, old: str, new: str) -> dict:
        text = self.path.read_text()
        count = text.count(old)
        if count == 0:
            return {"error": "String to replace was not found in the file."}
        self.path.write_text(text.replace(old, new))
        return {"result": f"Replaced {count} occurrence(s)."}


def build_tool() -> types.Tool:
    """Declare the file-editing tools exposed to the model."""
    return types.Tool(
        function_declarations=[
            types.FunctionDeclaration(
                name="read_file",
                description="Read and return the full current contents of your output file.",
                parameters_json_schema={"type": "object", "properties": {}},
            ),
            types.FunctionDeclaration(
                name="write_file",
                description="Overwrite your output file with the given content.",
                parameters_json_schema={
                    "type": "object",
                    "properties": {
                        "content": {
                            "type": "string",
                            "description": "The full new contents of the file.",
                        }
                    },
                    "required": ["content"],
                },
            ),
            types.FunctionDeclaration(
                name="append_file",
                description="Append text to the end of your output file.",
                parameters_json_schema={
                    "type": "object",
                    "properties": {
                        "content": {
                            "type": "string",
                            "description": "The text to append.",
                        }
                    },
                    "required": ["content"],
                },
            ),
            types.FunctionDeclaration(
                name="replace_in_file",
                description="Replace every occurrence of a string in your output file with another string.",
                parameters_json_schema={
                    "type": "object",
                    "properties": {
                        "old": {
                            "type": "string",
                            "description": "The exact text to find.",
                        },
                        "new": {
                            "type": "string",
                            "description": "The text to replace it with.",
                        },
                    },
                    "required": ["old", "new"],
                },
            ),
        ]
    )


class Conversation:
    def __init__(self, model: str, voice: str, system_instruction: str, output: OutputFile):
        self.model = model
        self.voice = voice
        self.system_instruction = system_instruction
        self.output = output
        self.session = None
        self.audio_in_queue: asyncio.Queue = asyncio.Queue()
        self.out_queue: asyncio.Queue = asyncio.Queue(maxsize=20)
        # True while the model is producing/playing audio. Used to gate the mic
        # so the model's own voice (picked up by the speakers) can't trip voice
        # activity detection and interrupt its response.
        self.model_speaking = False
        self.pya = pyaudio.PyAudio()
        self.dispatch = {
            "read_file": self.output.read_file,
            "write_file": self.output.write_file,
            "append_file": self.output.append_file,
            "replace_in_file": self.output.replace_in_file,
        }

    async def listen_audio(self):
        """Capture microphone audio and queue it for sending."""
        mic_info = self.pya.get_default_input_device_info()
        stream = await asyncio.to_thread(
            self.pya.open,
            format=FORMAT,
            channels=CHANNELS,
            rate=SEND_SAMPLE_RATE,
            input=True,
            input_device_index=mic_info["index"],
            frames_per_buffer=CHUNK_SIZE,
        )
        try:
            while True:
                data = await asyncio.to_thread(
                    stream.read, CHUNK_SIZE, exception_on_overflow=False
                )
                await self.out_queue.put(data)
        finally:
            stream.stop_stream()
            stream.close()

    async def send_realtime(self):
        """Forward queued microphone audio to the model.

        While the model is speaking (or audio is still queued to play), drop mic
        frames instead of sending them, so speaker bleed into the mic can't
        interrupt the model. This trades away barge-in; use headphones if you
        want to interrupt the model mid-response.
        """
        assert self.session is not None
        while True:
            data = await self.out_queue.get()
            if self.model_speaking or not self.audio_in_queue.empty():
                continue
            await self.session.send_realtime_input(
                audio=types.Blob(data=data, mime_type=f"audio/pcm;rate={SEND_SAMPLE_RATE}")
            )

    async def handle_tool_call(self, tool_call):
        assert self.session is not None
        responses = []
        for fc in tool_call.function_calls:
            args = fc.args or {}
            func = self.dispatch.get(fc.name)
            if func is None:
                result = {"error": f"Unknown tool: {fc.name}"}
            else:
                try:
                    result = func(**args)
                except Exception as e:  # surface tool errors back to the model
                    result = {"error": str(e)}
            print(f"[tool] {fc.name}({args}) -> {result}")
            responses.append(
                types.FunctionResponse(name=fc.name, id=fc.id, response=result)
            )
        await self.session.send_tool_response(function_responses=responses)

    async def receive_audio(self):
        """Read model responses: play audio and run tool calls."""
        assert self.session is not None
        while True:
            turn = self.session.receive()
            async for response in turn:
                if data := response.data:
                    self.model_speaking = True
                    self.audio_in_queue.put_nowait(data)
                    continue
                if response.tool_call:
                    await self.handle_tool_call(response.tool_call)
                server_content = response.server_content
                if server_content and server_content.interrupted:
                    # User barged in (only possible with headphones) -- drop any
                    # buffered playback.
                    while not self.audio_in_queue.empty():
                        self.audio_in_queue.get_nowait()
                if server_content and server_content.turn_complete:
                    self.model_speaking = False

    async def play_audio(self):
        """Play queued model audio through the speakers."""
        stream = await asyncio.to_thread(
            self.pya.open,
            format=FORMAT,
            channels=CHANNELS,
            rate=RECEIVE_SAMPLE_RATE,
            output=True,
        )
        try:
            while True:
                data = await self.audio_in_queue.get()
                await asyncio.to_thread(stream.write, data)
        finally:
            stream.stop_stream()
            stream.close()

    async def run(self):
        client = genai.Client()
        config = types.LiveConnectConfig(
            response_modalities=["AUDIO"],
            system_instruction=self.system_instruction,
            speech_config=types.SpeechConfig(
                voice_config=types.VoiceConfig(
                    prebuilt_voice_config=types.PrebuiltVoiceConfig(voice_name=self.voice)
                )
            ),
            tools=[build_tool()],
        )
        print(f"Connecting to {self.model} (voice: {self.voice})...")
        print(f"Output file: {self.output.path}")
        try:
            async with (
                client.aio.live.connect(model=self.model, config=config) as session,
                asyncio.TaskGroup() as tg,
            ):
                self.session = session
                print("Connected. Start talking -- press Ctrl-C to stop.\n")
                tg.create_task(self.listen_audio())
                tg.create_task(self.send_realtime())
                tg.create_task(self.receive_audio())
                tg.create_task(self.play_audio())
        finally:
            self.pya.terminate()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run a live audio conversation with a Gemini Live model that can edit an output file.",
    )
    parser.add_argument("prompt_file", type=Path, help="Path to the system-prompt text file.")
    parser.add_argument("output_dir", type=Path, help="Directory in which to create the per-run output file.")
    parser.add_argument("--model", default=DEFAULT_MODEL, help=f"Live model to use (default: {DEFAULT_MODEL}).")
    parser.add_argument("--voice", default=DEFAULT_VOICE, help=f"Prebuilt voice name (default: {DEFAULT_VOICE}).")
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    if not args.prompt_file.is_file():
        print(f"error: prompt file not found: {args.prompt_file}", file=sys.stderr)
        return 1
    system_instruction = args.prompt_file.read_text()

    args.output_dir.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    output = OutputFile(args.output_dir / f"conversation-{stamp}.md")

    conversation = Conversation(
        model=args.model,
        voice=args.voice,
        system_instruction=system_instruction,
        output=output,
    )

    try:
        asyncio.run(conversation.run())
    except KeyboardInterrupt:
        print("\nEnding conversation.")
    except ExceptionGroup as eg:
        traceback.print_exception(eg)
        return 1

    print(f"\nSaved to {output.path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
