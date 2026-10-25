# Alien::sqlite_vec House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They
load as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish
nothing until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

The sqlite-vec SQLite extension for vector search, built and exposed as an Alien. Read
first: the `alienfile` (probe/download/build/gather).

## Agent team

| Task | Agent |
|---|---|
| Implement / refactor / debug the alienfile, `lib/Alien/sqlite_vec.pm`, or `t/` | `alien-sqlite-vec-worker` (default) |
| Commits, `Changes`, card → done, pre-release audit | `alien-sqlite-vec-release-manager` |
| Read-only research, audit, gap analysis | `alien-sqlite-vec-worker` ("read-only, change nothing") |

Behavior-relevant = the alienfile (probe/download/build/gather), the cc invocation and its
flags, the `sqlite3ext.h` lookup, the `dynamic_libs`/`ffi_name` contract, and the tests.
Pure prose docs and changelog notes are not.

## Twin coupling — SQLite::VecDB

`SQLite::VecDB` (repo `p5-sqlite-vecdb`) consumes this Alien as its binding substrate. This
repo owns only download + compile + exposing the extension. **Never edit
`p5-sqlite-vecdb` directly**, and the twin's own uncommitted work is off-limits. A change
touching the consumer contract (the `dynamic_libs` path, `ffi_name`, the built `vec0`
surface) is a karr ticket on the twin's board. Background: skill `alien-sqlite-vec-core`.

## Release

`perl Makefile.PL && make test` is fine anytime too.

## Hazards — the traps that make the wrong thing look right

Mechanism and background: skill `alien-sqlite-vec-core`.

- **The extension must land in `<stage>/dynamic/`.** `Alien::Base->dynamic_libs` scans
  only that subdir. Compile it anywhere else and every test still parses, but
  `dynamic_libs` returns empty and the distribution silently exposes nothing.
- **`sqlite3ext.h` comes from DBD::SQLite's share dir first.** A build failure blaming
  `sqlite-vec.c` is usually the header lookup coming up empty — fix the lookup, not the
  source.
- **The build fetches v0.1.6 from GitHub at install time.** The source is not vendored, so
  a build needs network. Bumping the `0.1.6` string is a maintainer decision with a
  `SQLite::VecDB` re-test — never a routine update.
- **`darwin` needs `-dynamiclib`, everyone else `-shared`.** `$Config{cc}`/`$Config{dlext}`
  drive the compile — never hardcode `gcc`/`so`.

## Perl / Alien specifics — reference, don't restate

sqlite-vec build invariants and the consumer contract: skill `alien-sqlite-vec-core`.
Generic alienfile/Alien::Base mechanics: `perl-alien`. Perl house style: `getty-perl-core`.
Release flow: `getty-perl-release-author-getty` / `perl-release-dist-ini` — all
force-loaded for `alien-sqlite-vec-*` agents.
