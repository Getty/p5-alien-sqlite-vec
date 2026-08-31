---
name: alien-sqlite-vec-core
description: "Use when working on Alien::sqlite_vec — the alienfile that downloads and compiles sqlite-vec v0.1.6 into a loadable SQLite extension, the cc build that emits dynamic/libvec.<dlext>, the sqlite3ext.h lookup, the dynamic_libs/ffi_name contract this Alien exposes, or the boundary with its SQLite::VecDB consumer. Covers why share-only, why a runtime-loadable .so and not a link library, and the sqlite3ext.h dependency on DBD::SQLite."
---

# Alien::sqlite_vec — what this distribution actually decides

`Alien::sqlite_vec` is a thin `Alien::Base` wrapper whose whole job is to hand a
**runtime-loadable SQLite extension built from sqlite-vec v0.1.6** to Perl consumers —
chiefly `SQLite::VecDB` — through `Alien::sqlite_vec->dynamic_libs`. sqlite-vec adds
`vec0` virtual tables and KNN vector search *inside* SQLite.

Generic alienfile / Alien::Base mechanics live in skill `perl-alien`; the Perl/C
boundary in skill `perl-xs`. This skill is only the sqlite-vec-specific invariants —
read it before touching `alienfile` or reasoning about why a consumer got no extension.

## Not a link-time Alien — a loadable extension

This is the fact a reader coming from a normal Alien will get wrong. Nothing here is
consumed with `cflags`/`libs` at a consumer's compile time, and there is **no XS in this
distribution**. The product is a single shared object that SQLite `dlopen`s at *runtime*
via its `load_extension` mechanism. The entire consumer contract is:

```perl
my ($vec_path) = Alien::sqlite_vec->dynamic_libs;   # path to the built libvec.<dlext>
$dbh->sqlite_enable_load_extension(1);
$dbh->do("SELECT load_extension(?)", {}, $vec_path); # now vec0 tables exist
```

`dynamic_libs` returns that path because the build writes the library into a
`dynamic/` subdirectory of the Alien's stage — `Alien::Base->dynamic_libs` scans exactly
that subdir. Emit the library anywhere else and `dynamic_libs` comes back empty and the
distribution silently does nothing. The build also sets `runtime_prop->{ffi_name} = 'vec'`
for FFI consumers that resolve the library by name.

## share-only — there is no system sqlite-vec

`probe sub { 'share' }` forces the share path unconditionally: sqlite-vec has no stable
system packaging, so there is no `sys`/pkg-config branch to write and none to maintain.
Every install builds from source.

## v0.1.6 is fetched from upstream, not vendored

`start_url` points at the GitHub release amalgamation tarball
(`.../releases/download/v0.1.6/sqlite-vec-0.1.6-amalgamation.tar.gz`) via
`plugin 'Download'` + `plugin 'Extract' => 'tar.gz'`. The source is **not** bundled in
this repo, so a network fetch happens in every install — unlike a `Fetch::Local` Alien,
this one does not build air-gapped. The `0.1.6` version string lives in `start_url` (tag
and filename); a bump is a deliberate maintainer decision (sqlite-vec's `vec0` on-disk
and API surface can shift between releases and would ripple into `SQLite::VecDB`), never
a routine update — change every occurrence together and re-run the consumer's tests.

## The build is one cc of the amalgamation

The `build sub` compiles the single `sqlite-vec.c` amalgamation into a loadable module:

```
cc -O2 -fPIC <-shared|-dynamiclib> <-I sqlite3ext.h dir> sqlite-vec.c -o <stage>/dynamic/libvec.<dlext>
```

- `-shared` on most platforms, **`-dynamiclib` on darwin** (`$^O eq 'darwin'`).
- `$Config{cc}` and `$Config{dlext}` come from the running perl — do not hardcode `gcc`
  or `so`; the extension filename is `libvec.$dlext` so it matches the platform loader.
- `-fPIC` is load-bearing: the object is a position-independent shared module SQLite maps
  at runtime.

## The sqlite3ext.h dependency — why DBD::SQLite matters at build time

Compiling a SQLite *extension* needs `sqlite3ext.h` (the extension ABI header), not the
full amalgamation. The alienfile finds it in order:

1. `DBD::SQLite`'s `File::ShareDir::dist_dir('DBD-SQLite')` share dir — the primary source,
   which is why DBD::SQLite is effectively a build-time prerequisite and why the README
   says "SQLite development headers (provided by DBD::SQLite)".
2. fallback `-I/usr/include` or `-I/usr/local/include` if a system `sqlite3ext.h` exists.

If neither is found the compile still runs without `-I` and will fail on the missing
header — that failure means the header lookup came up empty, not that sqlite-vec.c is
broken. Keep this lookup working before blaming the source.

## lib/Alien/sqlite_vec.pm carries no logic

It is `use parent 'Alien::Base';` plus POD — `$VERSION` (dzil-managed) and the synopsis.
Everything a consumer needs comes from `runtime_prop`/`dynamic_libs`, set in the
alienfile. Do not add methods here.

## The consumer contract and the smoke test

`t/load.t` asserts exactly what the distribution promises: `alien_ok`, `dynamic_libs`
returns at least one path, and that path matches `/vec/`. Those are the reason the dist
exists — a change that breaks any of them breaks `SQLite::VecDB`'s ability to load the
extension.

## Boundary with SQLite::VecDB (the twin)

`SQLite::VecDB` (repo `p5-sqlite-vecdb`) is the high-level vector-database API and the
primary consumer of this Alien — it takes the extension path from
`Alien::sqlite_vec->dynamic_libs` and does the DBI/`load_extension` wiring, `vec0`
virtual-table management and query API. **This Alien only downloads, compiles and exposes
the extension.** No DBI handles, no SQL, no vector-search logic belong here — that all
lives in the twin. Coupling and cross-repo routing: see the rules file; changes that
affect the consumer contract are a ticket on the twin's board, never a direct edit there.
