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

Each run also writes a transcript file alongside the output file, capturing both
sides of the spoken conversation as text and appending to it as the
conversation unfolds.

The model can optionally be given read-only access to a directory (via
--read-dir). Those tools take a path argument, but every path is resolved and
checked to stay inside the directory, so the model cannot read anything outside
of it.

On startup the model is also seeded with the contents of any AGENTS.md files
found in that directory and its parents (most general first, most specific
last), so it begins the conversation already aware of the project's context.

Usage:
    conversation.py <prompt-file> <output-dir> [--read-dir <dir>]

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
DEFAULT_VOICE = "Charon"

AGENTS_FILENAME = "AGENTS.md"

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


class Transcript:
    """An append-only text log of the spoken conversation.

    Audio transcriptions arrive as a stream of small text fragments for each
    speaker. We append fragments as they come so the file stays current even if
    the run is interrupted, writing a `Speaker:` header only when the speaker
    changes so consecutive fragments read as continuous turns.
    """

    def __init__(self, path: Path):
        self.path = path
        self.path.touch()
        self._last_speaker: str | None = None

    def add(self, speaker: str, text: str) -> None:
        if not text:
            return
        with self.path.open("a") as f:
            if speaker != self._last_speaker:
                f.write("\n\n" if self._last_speaker is not None else "")
                f.write(f"{speaker}: ")
                self._last_speaker = speaker
            f.write(text)


class ReadDir:
    """A directory the model may read from, and nothing outside of it.

    Tools take a path argument, but every path is resolved against the
    directory root and rejected if it escapes (via symlinks, `..`, or absolute
    paths), so sandboxing holds even though paths are model-controlled.
    """

    def __init__(self, root: Path):
        self.root = root.resolve(strict=True)
        if not self.root.is_dir():
            raise NotADirectoryError(f"{self.root} is not a directory")

    def _resolve(self, path: str) -> Path:
        """Resolve a model-supplied path and confirm it stays under the root."""
        candidate = (self.root / path).resolve()
        if candidate != self.root and self.root not in candidate.parents:
            raise PermissionError(f"Path is outside the readable directory: {path}")
        return candidate

    def list_dir(self, path: str = ".") -> dict:
        target = self._resolve(path)
        if not target.is_dir():
            return {"error": f"Not a directory: {path}"}
        entries = []
        for child in sorted(target.iterdir()):
            entries.append(child.name + ("/" if child.is_dir() else ""))
        return {"result": entries}

    def read_path(self, path: str) -> dict:
        target = self._resolve(path)
        if not target.is_file():
            return {"error": f"Not a file: {path}"}
        try:
            return {"result": target.read_text()}
        except UnicodeDecodeError:
            return {"error": f"File is not valid UTF-8 text: {path}"}


def load_agents_context(start: Path) -> tuple[str, list[Path]]:
    """Collect AGENTS.md files from `start` up through its parents.

    Walks from `start` to the filesystem root, gathering any AGENTS.md files,
    then orders them most-distant-ancestor first so the most specific (closest)
    guidance appears last. Returns the formatted context block and the list of
    files used (closest-last), both empty if none were found.
    """
    start = start.resolve()
    files: list[Path] = []
    for directory in [start, *start.parents]:
        candidate = directory / AGENTS_FILENAME
        if candidate.is_file():
            files.append(candidate)
    files.reverse()  # outermost first, closest last

    sections = []
    used: list[Path] = []
    for path in files:
        try:
            text = path.read_text()
        except (UnicodeDecodeError, OSError):
            continue
        sections.append(f"===== {path} =====\n{text}")
        used.append(path)

    if not sections:
        return "", []

    block = (
        "The following is project context loaded from AGENTS.md files in the "
        "working directory and its parents, ordered from the outermost directory "
        "inward. Treat it as background information about the directory you are "
        "working with.\n\n" + "\n\n".join(sections)
    )
    return block, used


def build_tools(read_dir: "ReadDir | None") -> list[types.Tool]:
    """Declare the tools exposed to the model.

    Always includes the output-file editing tools. When a readable directory is
    configured, also includes read-only directory tools.
    """
    tools = [build_output_tool()]
    if read_dir is not None:
        tools.append(build_read_dir_tool())
    return tools


def build_read_dir_tool() -> types.Tool:
    """Declare the read-only directory tools exposed to the model."""
    return types.Tool(
        function_declarations=[
            types.FunctionDeclaration(
                name="list_dir",
                description=(
                    "List the entries of a directory within the readable directory. "
                    "Directories are suffixed with '/'. Use '.' for the root."
                ),
                parameters_json_schema={
                    "type": "object",
                    "properties": {
                        "path": {
                            "type": "string",
                            "description": "Directory path relative to the readable directory root. Defaults to '.'.",
                        }
                    },
                },
            ),
            types.FunctionDeclaration(
                name="read_path",
                description="Read and return the full contents of a file within the readable directory.",
                parameters_json_schema={
                    "type": "object",
                    "properties": {
                        "path": {
                            "type": "string",
                            "description": "File path relative to the readable directory root.",
                        }
                    },
                    "required": ["path"],
                },
            ),
        ]
    )


def build_output_tool() -> types.Tool:
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
    def __init__(
        self,
        model: str,
        voice: str,
        system_instruction: str,
        output: OutputFile,
        transcript: Transcript,
        read_dir: "ReadDir | None" = None,
    ):
        self.model = model
        self.voice = voice
        self.system_instruction = system_instruction
        self.output = output
        self.transcript = transcript
        self.read_dir = read_dir
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
        if self.read_dir is not None:
            self.dispatch["list_dir"] = self.read_dir.list_dir
            self.dispatch["read_path"] = self.read_dir.read_path

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
                audio=types.Blob(
                    data=data, mime_type=f"audio/pcm;rate={SEND_SAMPLE_RATE}"
                )
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
                server_content = response.server_content
                if server_content:
                    if it := server_content.input_transcription:
                        self.transcript.add("You", it.text)
                    if ot := server_content.output_transcription:
                        self.transcript.add(self.voice, ot.text)
                if data := response.data:
                    self.model_speaking = True
                    self.audio_in_queue.put_nowait(data)
                    continue
                if response.tool_call:
                    await self.handle_tool_call(response.tool_call)
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
            input_audio_transcription=types.AudioTranscriptionConfig(),
            output_audio_transcription=types.AudioTranscriptionConfig(),
            system_instruction=self.system_instruction,
            speech_config=types.SpeechConfig(
                voice_config=types.VoiceConfig(
                    prebuilt_voice_config=types.PrebuiltVoiceConfig(
                        voice_name=self.voice
                    )
                )
            ),
            tools=build_tools(self.read_dir),
        )
        print(f"Connecting to {self.model} (voice: {self.voice})...")
        print(f"Output file: {self.output.path}")
        print(f"Transcript file: {self.transcript.path}")
        if self.read_dir is not None:
            print(f"Readable directory: {self.read_dir.root}")
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
    parser.add_argument(
        "prompt_file", type=Path, help="Path to the system-prompt text file."
    )
    parser.add_argument(
        "output_dir",
        type=Path,
        help="Directory in which to create the per-run output file.",
    )
    parser.add_argument(
        "--read-dir",
        type=Path,
        default=None,
        help="Directory the model may read from (read-only, sandboxed to this directory).",
    )
    parser.add_argument(
        "--model",
        default=DEFAULT_MODEL,
        help=f"Live model to use (default: {DEFAULT_MODEL}).",
    )
    parser.add_argument(
        "--voice",
        default=DEFAULT_VOICE,
        help=f"Prebuilt voice name (default: {DEFAULT_VOICE}).",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    if not args.prompt_file.is_file():
        print(f"error: prompt file not found: {args.prompt_file}", file=sys.stderr)
        return 1
    system_instruction = args.prompt_file.read_text()

    read_dir = None
    if args.read_dir is not None:
        try:
            read_dir = ReadDir(args.read_dir)
        except (FileNotFoundError, NotADirectoryError):
            print(f"error: read directory not found: {args.read_dir}", file=sys.stderr)
            return 1

    # Seed the model with AGENTS.md context from the directory it works in
    # (the readable directory if given, otherwise the current directory).
    context_root = read_dir.root if read_dir is not None else Path.cwd()
    agents_context, agents_files = load_agents_context(context_root)
    if agents_context:
        system_instruction = f"{system_instruction}\n\n{agents_context}"
        print(f"Loaded {len(agents_files)} AGENTS.md file(s):")
        for path in agents_files:
            print(f"  - {path}")

    args.output_dir.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    output = OutputFile(args.output_dir / f"conversation-{stamp}.md")
    transcript = Transcript(args.output_dir / f"transcript-{stamp}.md")

    conversation = Conversation(
        model=args.model,
        voice=args.voice,
        system_instruction=system_instruction,
        output=output,
        transcript=transcript,
        read_dir=read_dir,
    )

    try:
        asyncio.run(conversation.run())
    except KeyboardInterrupt:
        print("\nEnding conversation.")
    except ExceptionGroup as eg:
        traceback.print_exception(eg)
        return 1

    print(f"\nSaved output to {output.path}")
    print(f"Saved transcript to {transcript.path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
