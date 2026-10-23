# Claude Code

How to work. Freeva domain rules: [AGENTS.md](AGENTS.md). PR/DoD: [CONTRIBUTING.md](CONTRIBUTING.md).

## Understand
- Read existing code and patterns before changing anything.
- Simple tasks: act directly. Complex or high-risk tasks: brief plan, then implement.
- Ask only when ambiguity would change the outcome.

## Scope
- Stick to the request / task ID. No drive-by refactors or extra features.
- Prefer the simplest fix that meets DoD. No new dependencies unless required.
- Do not assume commands or config — inspect the repo when needed.

## Verify
- Run the tests/lint/analyze that match what you touched.
- Never claim done without verification; say clearly what you could not run.

## Finish
- Complete the task, not just the plan. Summarize: what changed, what was verified, any blockers.
- Commit / push / PR only when asked. No force-push to `main`. No committing secrets.
