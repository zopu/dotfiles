#!/usr/bin/env bun
/**
 * UserPromptSubmit hook
 * Prompts Claude to use the work-completion-announcer agent
 * after completion.
 */

const input = await Bun.stdin.text();

let data: any;
try {
	data = JSON.parse(input);
} catch (error) {
	console.error(`Error: Invalid JSON input: ${error}`);
	process.exit(1);
}

const additionalContext = `After completing this task, prompt the work-completion-announcer agent to alert the user. Task start time: ${new Date().toLocaleString()}`;

const output = {
	hookSpecificOutput: {
		hookEventName: "UserPromptSubmit",
		additionalContext,
	},
};

console.log(JSON.stringify(output));
