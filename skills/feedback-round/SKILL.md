---
name: feedback-round
description: Capture the owner's feedback at conversation speed while they test live — instant ack with ID + restatement, async enrichment by a persistent scribe subagent, append-only revisions, triaged close. Use when the owner starts testing and drops rapid-fire findings, opens a UAT round (paseo-dev-loop §5), or says "new round" / "feedback round" / "start testing".
---

# feedback-round — rapid feedback capture during live testing

The owner is testing; items arrive faster than they can be investigated. The contract: **capture never blocks, investigation never interrupts.** The main agent is the capturer and the round file's only writer; investigation is delegated. Never investigate at capture time.

## Storage

- One file per round: `.feedback/round-<X>.md` in the worktree. The file is the source of truth — a fresh session resumes the round from it.
- Keep it out of the repo without touching the repo: ensure `.feedback/` is listed in `$(git rev-parse --git-common-dir)/info/exclude` (the local, uncommitted ignore). The owner commits a round log deliberately if they ever want it kept.
- Rounds are lettered `A, B, C…` per effort (inside paseo-dev-loop §5, the UAT round letter *is* the round). Item IDs inherit the letter: `A1, A2…`.

## Roles

- **Capturer (this session):** assigns the ID, appends the item (owner's words verbatim + one-line restatement — the restatement doubles as a "did I hear you right?" check for dictation), acks, forwards to the scribe in the background, and is immediately free for the next item.
- **Scribe:** one persistent Paseo subagent per round (not per item), launched at round open — profile named `Scribe` if one exists, else fallback claude / `claude-sonnet-5`, high effort, `auto` mode. **Brief it at launch:** the round's context header plus the settled rulings and known gotchas for the area under test — regression-vs-ruling detection comes from being handed the history, not from model size. Remind it to use the repo's codebase-navigation tooling where the repo docs provide one (knowledge graph, query tools) instead of cold grepping. It receives forwarded items serially and enriches each: where in the code it likely lives, duplicate/relative of an earlier item, regression of a settled ruling, severity guess. **Strictly read-only — code and logs only; it never drives the app or touches the env the owner is testing.** Mechanics for launching/forwarding: the `paseo` skill.
- Findings return as notifications; the capturer attaches them to the item and surfaces one or two lines to the owner, who may pull the thread ("discuss A3") or keep testing.

## Capture protocol

Ack format: `**A3** ✓ — <one-line restatement>` (+ queue depth if items are pending enrichment). Additionally capture, when present in the owner's words:

- **Type:** `issue` (default) · `idea` · `question` · `keep` ("this is right — don't change it").
- **Owner severity** ("blocker:", "minor:", …) — the owner's tag always wins over the scribe's guess.
- Screenshots/pastes are items like any other.

**Capture-only discipline:** no fixing during the round, however trivial the item looks, unless the owner explicitly invites it — the no-mutations-while-testing rule applies to the whole round.

## Revisions (append-only, natural language)

- **revise** — "revise A3: only on mobile" or "actually, the last one…" (resolve "the last one" to the most recent item). Revisions append; originals stay.
- **retract** — "drop A2" → status `retracted`, never deleted; can be un-retracted.
- **discuss** — conversation on the item; the outcome is recorded on it as a ruling. Rulings are settled — later rounds don't re-litigate them.
- Cross-round: "A3 is still broken" in round B links the items and marks recurrence.

## Close ("close the round")

1. Final sweep across the whole list — dedup and cluster (per-item enrichment can't see across items), fill missing severities.
2. Sort into three buckets:
   - **Fix batch** → the paseo-dev-loop fix pass (issues, ordered by severity).
   - **Ideas** → a planning conversation. Never into the fix batch — unplanned work doesn't enter the loop (entry contract).
   - **Needs ruling** → questions and disputed items, listed for the owner.
3. Carry unresolved items forward when the next round opens; note `keep` items as guardrails.
4. Optional, on the owner's ask: promote items to Linear.
5. Retire the scribe.

## Item format

```markdown
## A3 — 14:02 · issue · open
**Owner:** confirm dialog loses focus when closing (verbatim)
**Read as:** focus loss on dialog close
**Scribe:** likely UModal focus-trap; resembles PSY-301 fix — possible regression; sev: minor
**Trail:** 14:11 revised — mobile only · 14:20 ruling: fix in this batch
```

## Degradation

Capture depends on nothing — only the scribe degrades. Say so whenever running below tier 1, and never let enrichment ambition slow capture down.

1. **Paseo scribe** (normal): as above.
2. **No Paseo, plain session:** a **native background subagent** as scribe — spawn once at round open (model `sonnet`, same briefing), forward each item as a follow-up message to the same agent so it keeps its memory of earlier items. Works because the die-between-turns gotcha is a Paseo-hosted-session problem; it doesn't apply outside Paseo. **Guard:** if the session is Paseo-hosted but Paseo tools are unavailable (`PASEO_TERMINAL_ID` set, no tools), background native agents do die — skip to 3.
3. **No scribe possible:** capture inline, enrich everything once at close as part of the final sweep.
