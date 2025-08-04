## Refactor/Cleanup this code

Review the changes we're making in this commit looking for cleanup/refactoring opportunities. DO NOT perform any code changes without confirming with the user first.

Suggest only improvements that preserve functionality. No features or user-visible changes please.
Only suggest changes to code that we're currently changing (i.e. would change when we check into git).

Pay specific attention to:
- Are there low-value comments which duplicate the code.
- Are any comments discussing changes being made? Comments checked in should be about the current state of the code vs things being changed.
- Is there any duplicate code?
- Are we leaving any dead code? 
- Are we introducing any unneeded layers of abstraction where inlining code would clarify things?
- Have we left any small functions that are only called once where the code would be clearer if inlined?
- Was there anything we've added for debugging purposes that is no longer needed?
- Have you added code to any function that has become long (>40 LoC) and could potentially be split up?
- Is code added consistent with existing code?
- Have we disabled any linter warnings that we could re-enable? 
- Have we added any complicated logic that is not tested?
- Do any functions/methods that we've added have names that are redundant with their parameters e.g. "func checkWidget(w Widget)" should probably be "func check(w Widget)"
- Are there any constants or variables where units might be unclear? Particularly any time constants/variables should have their unit (s, ms, us, ticks, etc) be clear either by their name or by the name of their type.
- Are constants defined close to where they're used?
- Are all added TypeScript types defined close to where they are used?

## Any Specific Concerns

$ARGUMENTS
