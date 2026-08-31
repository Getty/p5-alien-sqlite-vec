# CLAUDE.md

Guidance for Claude Code in this repository. `Alien::sqlite_vec` is an `Alien::Base`
wrapper that downloads **sqlite-vec v0.1.6** and compiles it into a runtime-loadable
SQLite extension, handed to consumers (chiefly `SQLite::VecDB`) via
`Alien::sqlite_vec->dynamic_libs`.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself — the
principle, the lane definition, this dist's hazards and the `SQLite::VecDB` twin coupling
are in `.claude/rules/alien-sqlite-vec-rules.md` (auto-loaded every turn).

| Task | Agent |
|---|---|
| Implement / refactor / debug the alienfile, `lib/Alien/sqlite_vec.pm`, or `t/` | `alien-sqlite-vec-worker` (default) |
| Pre-release audit | `alien-sqlite-vec-release-checker` |

The agents carry their knowledge via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. The sqlite-vec specifics — why share-only, the
`dynamic/libvec.<dlext>` output, the `sqlite3ext.h` lookup, the consumer contract — live
in skill `alien-sqlite-vec-core` under `.claude/skills/`; the rest of the skills there are
hardlinks from the shared library, maintained via `manage-skills` in their home repos.

## Build / test

```bash
cpanm --installdeps .
perl Makefile.PL && make test    # full download + share build + smoke test
dzil test
```

The build fetches the v0.1.6 tarball from GitHub and needs a C compiler plus
`sqlite3ext.h` (from DBD::SQLite's share dir). Coordination is a `karr` board in this repo
(`karr board`). Never `dzil release` without the maintainer's explicit go-ahead.
