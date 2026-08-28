---
name: paseo-dev-loop
description: The Paseo-orchestrated execution pipeline for any agreed coded change — entry contract, profile-launched implementer and persistent reviewer, exit-code gate, three review rounds, owner UAT rounds, PR-as-ready. Roles resolve from Paseo agent profiles with hardcoded fallbacks; bindings (gate commands, seeds, red lines) are gathered from each repo's own docs. Use when starting implementation of a planned change, spawning implementation or review agents, running review rounds, or shipping.
---

# paseo-dev-loop — the execution pipeline

The device-level engine for how agreed work gets built, reviewed, and shipped. It is **orchestration and policy only** — techniques live in the referenced skills. **Reference, never restate:** if a section here starts teaching how to do TDD, review, or simplification, that's duplication — replace it with the reference.

**Planning is not part of this loop.** Ideation, specs, requirement interviews, and committees happen in interactive sessions before it (`agent-skills:idea-refine`, `agent-skills:interview-me`, `agent-skills:spec-driven-development`, `/paseo-committee`). The loop starts where decisions end.

## Bindings

Each repo supplies the loop's specifics: gate commands, seed scripts, env playbook, declared red lines, repo gotchas. Gather them from the repo's own agent docs (AGENTS.md / CLAUDE.md — typically its verification and local-development sections); repos stay agnostic about this workflow and never need to reference it. If a repo documents no gate at all, propose one before running the loop.

## Entry contract

Input: an agreed plan, spec, or ticket with acceptance criteria — or a task trivial enough not to need one. If a non-trivial ask arrives unplanned, stop and route it to a planning conversation first. Do not plan inside the loop. (Micro-planning — ordering the agreed work, choosing commit boundaries — is execution and stays inside.)

## Roles and transport

The session running this loop is the **orchestrator**: it delegates, supervises, triages, and reports — it does not write the code. Work is delegated to **Paseo subagents**. The **`paseo` skill is the reference for all mechanics** — launching from profiles, follow-up prompts, workspace scripts, heartbeats, waiting/notifications; follow it rather than improvising tool calls. Do not use native background subagents for implementation or review — they die between turns; Paseo sessions persist, appear in the Subagents track, and can be re-prompted. While a subagent runs, don't poll it — rely on Paseo's finish/permission notifications and do other work.

**Launch resolution ladder (what this loop adds on top of the `paseo` skill).** Try each tier in order; whenever any tier below 1 fires, say so in the report — which tier, and why:

1. **Profiles.** Pick by role: `Implementer` for code-writing delegation, `Reviewer` for review rounds — match by profile name or role words in the notes. The owner's profiles are the tuning layer: whatever they say wins over the defaults below.
2. **No matching profile (or none configured).** `create_agent` with the hardcoded defaults from the table — it usually means this machine's profiles aren't set up yet.
3. **Paseo unavailable entirely** (no Paseo tools in this session — unconfigured machine, headless run). Degrade to native **foreground** subagents for implementation (Claude, model `opus`, effort `xhigh` — the table's values still apply) and the `codex` CLI for review rounds (`codex exec … < /dev/null`, xhigh). Background native subagents stay forbidden; you lose persistence and the Subagents track, so keep delegations coarse-grained.
4. **No independent reviewer available at all** (no Paseo, no `codex` CLI): stop the review loop and tell the owner. Never quietly substitute a same-vendor self-review — a skipped round is visible, a self-graded one isn't.

| Role | Default launch (tiers 2–3) | Effort | Mode |
|---|---|---|---|
| Implementer | claude / `claude-opus-5` | xhigh | `auto` |
| Reviewer | codex / `gpt-5.6-sol` | xhigh | `auto-review` (eligible approvals route to Codex's auto-reviewer instead of stalling the round) |
| Search / exploration fan-out | small tier (Haiku / Sonnet) | — | — |

Either way, **behavior travels in the launch prompt** — profiles carry launch configuration only, never skills or instructions. The implementer's prompt names its skill pack (§2); the reviewer's prompt carries the lens checklist (§4).

Inline carve-out: tasks so small that the handoff costs more than the work are done inline by the orchestrator. If a subagent already holds the relevant context, route follow-ups to it instead of working inline.

## The pipeline

**1. Env** — bring up the project dev environment per the repo's env playbook (binding).

**2. Implement** — spawn the implementer with the agreed plan and its skill pack: `agent-skills:incremental-implementation`, `agent-skills:test-driven-development`; `agent-skills:debugging-and-error-recovery` when tests fail; `agent-skills:frontend-ui-engineering` plus the repo's UI stack skills for UI work. Owner-reviewable scenarios need their seed scripts (binding) built here, not later.

**3. Gate (blocking)** — run the repo's gate commands (binding). When the repo registers them as Paseo workspace scripts (`paseo.json`), run them through the workspace-script tools — supervised lifecycle, exit codes visible to everyone; otherwise run them in the shell and capture `$?`. **Exit codes are the only verdict — never judge by a summary line.** Full/slow suites run async, never as a blocking gate. Red gate → back to 2.

**4. Review loop (internal — before any PR)** — starts when the implementer declares closed and the gate is green. The reviewer is **one persistent subagent launched from the Reviewer profile**, created once and re-prompted per round, deliberately blind to the implementer's conversation; prefer a **different vendor** than the implementer so findings aren't self-graded — the profile decides the actual model. Each round: review the branch diff → findings batched into one fix pass (implementer) → re-gate (§3). **Three rounds is the standard.** A zero-findings round closes the loop early; high-stakes changes (declared red lines, auth/session code, schema migrations, large branches) get more than three.

- **Lenses per round:** `agent-skills:code-review-and-quality`, `agent-skills:code-simplification`. **Security is non-optional** when the diff touches auth, untrusted input, or a declared red line: run a Claude-side `security-auditor` pass (`agent-skills:security-and-hardening`) as its own subagent — a second, independent set of eyes on security, not one.
- **The lens checklist always travels in the reviewer's round prompt.** Never assume the reviewer can load Claude plugin skills — only Claude Code agents can, and the Reviewer profile may point to any provider.

**5. UAT rounds (owner-driven — still pre-PR)** — owner-visible work only; internal-only changes skip to 6. Before inviting the owner, walk the seeded scenario with the Paseo browser tools — broken basics never reach the owner. While the owner tests, capture their findings with the **`feedback-round`** skill — it owns intake, acks, revisions, and the round file; the rules below govern the round itself.

- **Rounds are lettered and batched:** findings collect into round A, B, C…; fix the batch → re-gate → invite the next round.
- **State between rounds belongs to the owner — never re-seed uninvited.** Re-seed when the owner asks, or when a fix invalidates the current state — and even then, flag it and get a go-ahead first. Seed scripts make reset cheap on demand, not mandatory.
- **Queue mode while the owner is testing:** no mutations to the running env under their feet. Batch fixes in an isolated worktree; land with one coordinated restart; re-seed only on the owner's call.
- **Rulings are settled:** record decisions the owner makes during rounds; later rounds do not re-litigate them.

**6. Ship** — only after the review loop (and UAT, when it applies) is closed: push, open the PR, create a CI heartbeat — the `paseo` skill's PR-babysitting use case ("keep checking this PR, fix new CI failures, report when all checks pass; stop after a bounded time") — and report: what changed, how it was verified, and decisions made on the owner's behalf. **An open PR means the work is ready** — never open one to collect feedback. **Merging is the owner's call:** execute a merge only when the owner explicitly asks for it in the current conversation — never uninvited, and never push to the default branch.

## Mid-flight planning (escape hatch)

When implementation uncovers something the plan didn't anticipate, the implementer never decides and never improvises: it stops the affected work, reports the fork to the orchestrator, and waits — its session stays alive, so waiting is cheap. The discussion happens at the orchestrator level:

- **The orchestrator decides alone** when the deviation doesn't change the agreed outcome: implementation tactics, internal structure, which existing pattern to follow, test approach, small enabling refactors — anything reversible within the branch that the owner wouldn't notice at UAT.
- **The owner decides** when it changes what was agreed: scope, user-visible behavior, schema or data meaning, security/privacy posture (a declared red line always qualifies), a large effort delta, or anything that conflicts with a prior ruling — rulings are settled, and only the owner unsettles them.
- **Litmus test:** would the owner be surprised at UAT? If yes, it's theirs.
- While waiting, the default is to wait; the orchestrator may explicitly release the implementer to continue clearly independent parts.
- **Every mid-flight decision is recorded:** owner calls become rulings; orchestrator calls get listed in the UAT invite and ship report as "decisions made on your behalf" — autonomy stays trustworthy only if it's auditable.

## Reporting

Reports are the audit trail of autonomy: gate results as exit codes, review rounds and their dispositions, UAT round logs, decisions made on the owner's behalf. Never report a background launch (dev server, `codex exec`, a long suite) as running without verifying real progress first; background `codex exec` needs `< /dev/null`.
