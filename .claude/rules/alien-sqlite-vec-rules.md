# Alien::sqlite_vec House Rules

Apply to every task in this repository unless explicitly overridden. Bias: caution over
speed on non-trivial work; use judgment on trivial tasks. Loaded automatically at launch
(same priority as `CLAUDE.md`). Subagents get their discipline from the skills
force-loaded via `briefing.skills` — this file is for the orchestrating agent.

## Engineering discipline

1. **Think before coding** — State assumptions. When uncertain, ask rather than guess.
   Push back when a simpler approach exists. Stop when confused; name what's unclear.
2. **Simplicity first, surgical changes** — Minimum code that solves the problem;
   nothing speculative. Touch only what you must; don't "improve" adjacent code or
   formatting. Match existing style.
3. **Tests verify intent** — Reproduce a failure before fixing it; leave a regression
   test behind. A test that can't fail when the logic changes is wrong.
4. **Fail loud** — "Done" is wrong if anything was skipped silently. Contradicting
   patterns: pick one, explain why, flag the other — don't blend. Surface uncertainty.

## Delegation

This rule depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): Do NOT touch behavior-relevant
  code yourself — delegate to `alien-sqlite-vec-worker`. Your lane: coordinate, inspect,
  plan, review diffs, run tests, edit non-behavioral docs. When in doubt,
  delegate. Why: only the `alien-sqlite-vec-*` agents get their skills force-loaded via
  `briefing.skills`; you get no briefing and would touch internals with too little
  context. Specialist lanes:

  | Task | Agent |
  |---|---|
  | Implement / refactor / debug the alienfile, `lib/Alien/sqlite_vec.pm`, or `t/` | `alien-sqlite-vec-worker` (default) |
  | Commits, `Changes`, card → done, pre-release audit | `alien-sqlite-vec-release-manager` |

- **You cannot spawn subagents** (you ARE an `alien-sqlite-vec-*` agent): The delegation
  lock does not apply — implement, refactor, debug and test per these rules.

Behavior-relevant = the alienfile (probe/download/build/gather), the cc invocation and
its flags, the `sqlite3ext.h` lookup, the `dynamic_libs`/`ffi_name` contract, and the
tests. Pure prose docs and changelog notes are not.

**Only `alien-sqlite-vec-release-manager` commits.** A worker leaves a commit-ready tree and hands its card
to `review`; you then dispatch `alien-sqlite-vec-release-manager` to cut the commit and close the card.

## Coordination — karr board (always in scope)

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope — just
use it, don't invoke the `kanban-issues-karr-coordination` skill first. Git-native kanban; state
lives in `refs/karr/*`; this repo has its own board.

- `karr list --compact` / `karr board` — open work · `karr show ID` — detail
- `karr create "Title" --priority high --tags a,b --body '…'` — new ticket
- `karr move ID in-progress --claim NAME` — start · `karr handoff ID --claim NAME --note "…"` — to review

**Serialize board mutations when fanning out.** Keep implementation work parallel if you
like, but collect results and loop `karr move`/`handoff`/`sync` sequentially — N landing
at once is a resource event, not a cheap command.

## Twin coupling — SQLite::VecDB

`SQLite::VecDB` (repo `p5-sqlite-vecdb`) consumes this Alien as its binding substrate:
it takes `Alien::sqlite_vec->dynamic_libs` and does the DBI/`load_extension` wiring,
`vec0` virtual tables and query API. This repo owns only download + compile + exposing
the extension. **Never edit `p5-sqlite-vecdb` directly.** A change touching the consumer
contract (the `dynamic_libs` path, `ffi_name`, the built `vec0` surface) is a karr ticket
on the twin's board — not a direct edit. The twin's own uncommitted work is off-limits.

## Release — never without permission

`perl Makefile.PL && make test` / `dzil build` / `dzil test` are fine anytime.
`dzil release` and any upload/deploy are STRICTLY forbidden without the maintainer's
explicit go-ahead — even if a plan or STATUS document lists "release" as the next step.
For anything heading toward release: stop and ask.

## Project hazards — the traps that make the wrong thing look right

- **The extension must land in `<stage>/dynamic/`.** `Alien::Base->dynamic_libs` scans
  only that subdir. Compile it anywhere else and every test still parses, but
  `dynamic_libs` returns empty and the whole distribution silently exposes nothing.
- **`sqlite3ext.h` comes from DBD::SQLite's share dir first.** A build failure blaming
  `sqlite-vec.c` is usually the header lookup coming up empty (no DBD::SQLite share dir,
  no system header) — fix the lookup, not the source.
- **The build fetches v0.1.6 from GitHub at install time** — the source is not vendored.
  A build needs network. Bumping the `0.1.6` string is a maintainer decision with a
  `SQLite::VecDB` re-test, never a routine update.
- **`darwin` needs `-dynamiclib`, everyone else `-shared`;** `$Config{cc}`/`$Config{dlext}`
  drive the compile — never hardcode `gcc`/`so`.

## Perl / Alien specifics — reference, don't restate

sqlite-vec build invariants and the consumer contract: skill `alien-sqlite-vec-core`.
Generic alienfile/Alien::Base mechanics: `perl-alien`. Perl house style: `getty-perl-core`.
Release flow: `getty-perl-release-author-getty` / `perl-release-dist-ini`. All force-loaded
for `alien-sqlite-vec-*` agents — do not duplicate them here.
