# AGENTS.md

- Official Mojo docs: https://mojolang.org/docs — verify any API you are not sure about against the v1 docs before coding; do not rely on pre-1.0 examples.

## Commands

- Toolchain: `just` + `pixi` (Mojo 1.x from `conda.modular.com/max`); `pixi run`/`just` recipes depend on the pixi env.
- `just setup` — creates/updates the pixi environment (`pixi install`); run this first on a fresh checkout.
- `just build` — compiles `src/main.mojo` to `./vortex` at the repo root; `just clean` removes it (and `just exe` runs it).
- `just run` — runs from source without building (`mojo run -I src src/main.mojo`).
- `just test <file> [--only <test-name>]` — runs a test file (from `tests/`); the recipe adds `-I src` so `server.*`, `database.*`, and `consts` imports resolve. Fails non-zero on any failure.
- `just test-all` — discovers and runs every `test_*.mojo` under `tests/`, failing non-zero if any file fails.
- `just mojo <args>` — passthrough to the `mojo` CLI.
- CI (`.github/workflows/ci.yml`): ubuntu-latest; installs `just` + `pixi`, then runs `just build`, `just test tests/server/test_db.mojo`, and a curl smoke test of the built `./vortex`. No linter or formatter config.

## Tests

- Files live in `tests/` at the repo root, mirroring the source packages: `tests/server/test_db.mojo` tests `src/database/database.mojo`. Each is a standalone entrypoint: `def test_*() raises` functions, auto-discovered by `std.testing.TestSuite.discover_tests[__functions_in_module()]().run()` in `main()`.
- Single test: `just test tests/server/test_db.mojo --only test_name` (`--skip` also exists).
- Gotcha: `Dict` iteration order is unspecified — never assert on `all_keys()` ordering, assert membership instead.

## Running the server

- Listens on port `8000` (binds all interfaces; the log line and CI curls use `127.0.0.1:8000`). A stale `vortex` process makes a new one fail with `bind() failed: errno=Address already in use` — `pkill -x vortex` first.
- Smoke test: `curl -s -X POST -d "store k some value" http://127.0.0.1:8000/`, then `fetch k` / `delete k` / `keys`; `GET /` and `GET /hello` print usage.
- The build is warning-free. Do not reintroduce deprecated forms (e.g. Layout-less `alloc[T](n)`).
- Mojo 1.0 memory API: `alloc(Layout[T](count=n))` returns an `Allocation` handle; its borrowed `unsafe_ptr()` keeps a generic origin and will NOT convert to a concrete `Pointer[T, MutUntrackedOrigin]`. At raw-pointer FFI boundaries (the `sockets.mojo` wrappers), take the exact raw pointer via `allocation^.unsafe_leak()` and release it with `pointer.unsafe_free()`.

## Architecture

- MVC HTTP server in Mojo 1.0, all under `src/`: `src/server/sockets.mojo` (libc FFI), `src/server/server.mojo` (accept loop + command dispatch), `src/server/router.mojo` (`METHOD path` -> thin handler), `src/server/http/` package (`HttpRequest`/`HttpResponse`, parsing lives in `HttpRequest.__init__`), `src/database/database.mojo` (`Database`).
- The freeform command endpoint (`POST /` and `POST /cmd`) is deliberately NOT in the stateless router; `HttpServer._dispatch_command` owns it.
- Mojo 1.0 has no module-level globals or capturing closures: long-lived state lives on the server-owned struct (`Database` inside `HttpServer`).
- Data is in-memory only and resets on process restart.

## Code style

- Verbose naming: fully spelled-out identifiers (`request`, `file_descriptor`, `bytes_received`, `index` for loop variables). No shorthand (`req`, `fd`, `buf`, `n`, `i`) except where it mirrors the libc API in `sockets.mojo`.
- Single-quoted string literals in code (including t-strings in `external_call`); docstrings stay triple-double-quoted. Strings containing an apostrophe stay double-quoted.
- Gotcha: `mojo format` re-normalizes single-quoted literals back to double quotes. Do not run the formatter over the source (or re-apply the single-quote style afterwards).
