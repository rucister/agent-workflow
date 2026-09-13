---
name: paseo-dev-loop
description: The Paseo-orchestrated execution loop for any agreed coded change — checks decide when it is done, not judgment: gate with executed counts, default-path evidence, a counterexample per acceptance clause, zero open blocking findings, PR-as-ready. Roles resolve from Paseo agent profiles with hardcoded fallbacks; bindings (gate commands, seeds, red lines) come from each repo's own docs. Use when the owner says "implement this", "build the plan", "start the loop", "ship it", "open the PR", or when starting implementation of a planned change or spawning an implementer.
---

# paseo-dev-loop

You are running a closed loop. The checks below decide when the work is done; no agent's judgment is the verifier. Policy only — techniques live in the referenced skills (reference, never restate). Planning happens before the loop (`idea-refine`, `interview-me`, `spec-driven-development`, `paseo-committee`); the loop starts where decisions end.

## Contract

**Input:** an agreed plan with acceptance clauses, or a task trivial enough to skip one. No plan → route to planning; never plan here. **Deliverable:** the plan's outcome or an agreed vertical slice exercised by its real consumer (`incremental-implementation`). Helpers are commits, never milestones, never reviewed alone. **Bindings** (gate commands, seeds, env playbook, red lines) come from the repo's own agent docs; repos never reference this workflow.

**Done when ALL pass** — recorded in the ledger:

- [HARD] Gate green: every gate command exits 0 AND executed-case counts ≥ the last green gate; no required case skipped, filtered, or never run. *Prove it:* the ledger's gate table.
- [HARD] Default path exercised: one success and the relevant failure scenarios through the real entry point (browser for UI, real calls for API/CLI); every boundary recorded real / controlled / untested. Supplied business decisions and controlled HTTP are never "real". *Prove it:* the boundary table.
- [HARD] Every acceptance clause survived an executed counterexample (`review-rounds`). *Prove it:* the clause table, with the commit that carries each counterexample as a test.
- [HARD] Open blocking findings = 0, and the reviewer of record is a different vendor than the implementer. *Prove it:* findings and roles tables.
- [HARD] Diff stays inside the plan's named files, or the ledger records why not. *Prove it:* `git diff --stat` against the plan.
- [JUDGMENT] Each commit names one change. *Judge:* the reviewer.

Green means ready for the owner's review, never shipped.

## Roles

**Orchestrator** (this session): delegates, gates, triages, writes the ledger; never writes code. **Implementer:** one persistent Paseo subagent per change, Implementer profile. **Reviewer:** one persistent subagent per change, Reviewer profile, other vendor, blind to the implementer's conversation and never to the goal — `review-rounds` owns it. **Security:** a separate subagent briefed with `security-and-hardening` whenever the diff touches auth, untrusted input, or a declared red line. **Owner:** rulings, UAT, the merge call.

Transport is Paseo; the `paseo` skill is the reference for every mechanic. Behavior travels in the launch prompt; profiles carry launch configuration only. Only the orchestrator spawns agents. Work smaller than its handoff is done inline. Parallel loops across changes are fine; within a change there is one implementer.

**Launch ladder** — say which tier fired: 1 profiles by role → 2 the table below → 3 no Paseo: native *foreground* subagents for implementation, `codex exec … < /dev/null` for review → 4 no independent reviewer: stop and tell the owner; never self-review. A same-vendor review yields **provisional**, never accepted.

| Role | Fallback (tiers 2–3) | Effort | Mode |
|---|---|---|---|
| Implementer | claude / `claude-opus-5` | xhigh | `auto` |
| Reviewer | codex / `gpt-5.6-sol` | xhigh | `auto-review` |

## Workspace

The delivery shape, decided in planning, decides the topology; unclear → ask the owner, never infer. **One PR:** one workspace = worktree = branch; the whole crew works in it; one writer on the tree at a time — the orchestrator is read-only while the implementer is active. **Phased PRs:** one workspace per phase; phases merging into an integration PR → the orchestrator holds the integration workspace; phases merging to the default branch → no orchestrator workspace. One dev stack per checkout (binding); archive a workspace when its PR merges.

## Ledger — state and trace

`.loop/<branch>.md` in the worktree; the orchestrator is its only writer; excluded through `$(git rev-parse --git-common-dir)/info/exclude` unless the owner commits it. It opens with the done checks and their current pass/fail, then: roles with agent id, provider and effort per round; gate table; boundary table; clause table; findings (id · class · round · disposition · commit); decisions made on the owner's behalf; rulings; spend per round. Written at every phase boundary. A fresh session resumes the loop from it, from git, and from the agent ids it names. Agents are archived only after its final state is written. Reports quote it and never restate it.

## Loop

1. **Env** up per the repo's playbook.
2. **Build:** the implementer gets the plan and `incremental-implementation`, `test-driven-development`; `debugging-and-error-recovery` on failure; `frontend-ui-engineering` plus the repo's UI skills for UI work. Commit small. Seeds for owner scenarios are built here.
3. **Gate** — HARD check 1. Red → 2.
4. **Evidence** — HARD check 2. Fails → 2, never into review.
5. **Review** — `review-rounds` with the branch, the plan, and the implementer as fix owner. Blocking findings → one fix pass → re-gate → next round. A fix pass that breaks a working scenario is reverted, not repaired. Polish is batched once at the end.
6. **UAT** (owner-visible work): re-walk the seeds after fix passes; `feedback-round` captures; rounds lettered and batched; the owner owns state — never re-seed uninvited; no mutations under the owner's feet; rulings are settled.
7. **Ship** when all checks pass: push, open the PR, start a CI heartbeat (`paseo` skill). PR means ready. Merge only on the owner's explicit ask in this conversation; never push to the default branch.

## Stop and tripwires

Stop when all checks pass, OR the round budget is spent (3 review rounds) — report pass/fail per check and let the owner decide on more, OR a tripwire fires. **Tripwires** — stop, report, do not recover:

- A test deleted, skipped, or edited to pass; a timeout raised or a dependency substituted to pass a gate.
- The diff grows round over round instead of shrinking toward green.
- The same check fails 3 rounds under different fixes → name the doubtful assumption and measure the failing boundary (`debugging-and-error-recovery`) before any further edit.
- Open blocking findings not decreasing for 2 rounds.
- The next round would exceed the change's spend cap (set by the owner in the plan; none set → ask).

## Mid-flight forks

The implementer stops and waits. The orchestrator decides what does not change the agreed outcome: tactics, internal structure, test approach. The owner decides scope, user-visible behavior, data meaning, security posture, declared red lines, large effort deltas, and anything against a ruling. Litmus: would the owner be surprised at UAT? Every decision goes to the ledger; owner calls become rulings.

## Reporting

Status words are precise: **implemented** = written; **verified** = observed on the default path, with the boundary record; **accepted** = all checks pass with a cross-vendor reviewer; **provisional** = same-vendor. Reports quote the ledger: checks, rounds with agent ids, spend, decisions made on the owner's behalf. Never report a background launch as running without verifying real progress.
