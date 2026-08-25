# AGENTS.md

## Commands

- Toolchain: `just` + `pixi` (Mojo 1.x from `conda.modular.com/max`).
- `just build` — compiles `src/main.mojo` to `./vortex` in the project root (not `src/`).
- `just run` — runs from source without building. `just clean` — removes the binary.
- `just test <file> [--only <test-name>]` — runs a test file (from `src/tests/`); the recipe adds `-I .` so `server.*` imports resolve. Fails non-zero on any failure.
- `just mojo <args>` — passthrough to the `mojo` CLI.
- CI (`.github/workflows/ci.yml`): ubuntu-latest; installs `just` + `pixi`, then runs `just build`, `just test tests/vortex_db_test.mojo`, and a curl smoke test of the built `./vortex`. No linter or formatter config.

## Tests

- Files live in `src/tests/` (`*_test.mojo`); each is a standalone entrypoint: `def test_*() raises` functions, auto-discovered by `std.testing.TestSuite.discover_tests[__functions_in_module()]().run()` in `main()`.
- Single test: `just test tests/vortex_db_test.mojo --only test_name` (`--skip` also exists).
- Gotcha: `Dict` iteration order is unspecified — never assert on `all_keys()` ordering, assert membership instead.

## Running the server

- Binds `127.0.0.1:8000`. A stale `vortex` process makes a new one fail with `bind() failed: errno=Address already in use` — `pkill -x vortex` first.
- Smoke test: `curl -s -X POST -d "store k some value" http://127.0.0.1:8000/`, then `fetch k` / `delete k` / `keys`; `GET /` and `GET /hello` print usage.
- The build is warning-free. Do not reintroduce deprecated forms (e.g. Layout-less `alloc[T](n)`).
- Mojo 1.0 memory API: `alloc(Layout[T](count=n))` returns an `Allocation` handle; its borrowed `unsafe_ptr()` keeps a generic origin and will NOT convert to a concrete `Pointer[T, MutUntrackedOrigin]`. At raw-pointer FFI boundaries (the `sockets.mojo` wrappers), take the exact raw pointer via `allocation^.unsafe_leak()` and release it with `pointer.unsafe_free()`.

## Architecture

- MVC HTTP server in Mojo 1.0, all under `src/`: `server/sockets.mojo` (libc FFI), `server/server.mojo` (accept loop + command dispatch), `server/router.mojo` (`METHOD path` -> thin handler), `server/http.mojo` (`Request`/`Response`), `server/parser.mojo`, `server/db.mojo` (`VortexDb`).
- The freeform command endpoint (`POST /` and `POST /cmd`) is deliberately NOT in the stateless router; `HttpServer._dispatch_command` owns it.
- Mojo 1.0 has no module-level globals or capturing closures: long-lived state lives on the server-owned struct (`VortexDb` inside `HttpServer`).
- Data is in-memory only and resets on process restart.

## Code style

- Verbose naming: fully spelled-out identifiers (`request`, `file_descriptor`, `bytes_received`, `index` for loop variables). No shorthand (`req`, `fd`, `buf`, `n`, `i`) except where it mirrors the libc API in `sockets.mojo`.
- Single-quoted string literals in code (including t-strings in `external_call`); docstrings stay triple-double-quoted. Strings containing an apostrophe stay double-quoted.
- Gotcha: `mojo format` re-normalizes single-quoted literals back to double quotes. Do not run the formatter over the source (or re-apply the single-quote style afterwards).
