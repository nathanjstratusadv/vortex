# AGENTS.md

- Official Mojo docs: https://mojolang.org/docs — verify any API you are not sure about against the v1 docs before coding; do not rely on pre-1.0 examples.

## Commands

- Toolchain: `just` + `pixi` (Mojo 1.x from `conda.modular.com/max`); `pixi run`/`just` recipes depend on the pixi env.
- `just setup` — creates/updates the pixi environment (`pixi install`); run this first on a fresh checkout.
- `just build` — compiles `src/main.mojo` to `./vortex` at the repo root; `just clean` removes it (and `just exe` runs it).
- `just run` — runs from source without building (`mojo run -I src src/main.mojo`).
- `just test <file> [--only <test-name>]` — runs a test file (from `tests/`); the recipe adds `-I src` so `server.*`, `database.*`, and `consts` imports resolve. Fails non-zero on any failure.
- `just test-all` — discovers and runs every `test_*.mojo` under `tests/`, failing non-zero if any file fails.
- `just lsp-wrap` — wraps `.pixi/envs/default/bin/mojo-lsp-server` with a script that execs the real binary (`mojo-lsp-server-real`) with `-I src` appended, so the PyCharm "Mojo Pro" plugin's language server resolves `vortex.*` imports. The plugin has no setting for LSP arguments and always launches the binary with an empty argument list, so this wrapper is the only injection point. Re-run after `just setup` (`pixi install` restores the env's bin). After applying, use "Restart Mojo LSP" in PyCharm's Tools menu.
- `just mojo <args>` — passthrough to the `mojo` CLI.
- CI (`.github/workflows/ci.yml`): ubuntu-latest; installs `just` + `pixi`, then runs `just build`, `just test tests/server/test_db.mojo`, and a curl smoke test of the built `./vortex`. No linter or formatter config.

## Tests

- Files live in `tests/` at the repo root, mirroring the source packages: `tests/server/test_db.mojo` tests `src/database/database.mojo`. Each is a standalone entrypoint: `def test_*() raises` functions, auto-discovered by `std.testing.TestSuite.discover_tests[__functions_in_module()]().run()` in `main()`.
- Single test: `just test tests/server/test_db.mojo --only test_name` (`--skip` also exists to skip one).
- Gotcha: tests import from `src` via `-I src` (the `test`/`test-all` recipes add it); import paths mirror source packages, e.g. `from server.http.request import HttpRequest`.
- Gotcha: `Dict` iteration order is unspecified — never assert on `all_keys()` ordering, assert membership instead.

## Running the server

- Listens on port `8000` (binds all interfaces; the log line and CI curls use `127.0.0.1:8000`). A stale `vortex` process makes a new one fail with `bind() failed: errno=Address already in use` — `pkill -x vortex` first.
- Smoke test: `curl -s -X POST -d "store k some value" http://127.0.0.1:8000/`, then `fetch k` / `delete k` / `keys`; `GET /` and `GET /hello` print usage.
- Requests are read with a single `recv` of up to 8192 bytes in `_read_request` (server.mojo) — no loop, so larger payloads are silently truncated. Keeping command payloads under 8 KB avoids surprising behavior.
- The build is warning-free. Do not reintroduce deprecated forms (e.g. Layout-less `alloc[T](n)`).
- Mojo 1.0 memory API: `alloc(Layout[T](count=n))` returns an `Allocation` handle; its borrowed `unsafe_ptr()` keeps a generic origin and will NOT convert to a concrete `Pointer[T, MutUntrackedOrigin]`. At raw-pointer FFI boundaries (the `sockets.mojo` wrappers), take the exact raw pointer via `allocation^.unsafe_leak()` and release it with `pointer.unsafe_free()`.

## Architecture

- MVC HTTP server in Mojo 1.0, all under `src/`:
  - `src/server/sockets.mojo` — libc FFI wrappers (`socket`/`bind`/`listen`/`accept`/`recv`/`send`/`close`, plus `fill_sockaddr_in`).
  - `src/server/server.mojo` — `HttpServer` accept loop + `_dispatch_command` (freeform commands). `_read_request` reads a single `recv` of up to 8192 bytes, so requests larger than the buffer are truncated.
  - `src/server/router.mojo` — `Router` maps `'METHOD path'` -> thin `Handler` (a `def ... raises thin -> None` comptime alias); stateless.
  - `src/server/http/` package — `HttpRequest`/`HttpResponse`/`HttpHeader`/`HttpBody`/`Status`/`status`. Request parsing lives in `HttpRequest.__init__`: request line (method/path/query), headers, and body split on the `\r\n\r\n` separator. `Status.__init__` silently coerces any code outside the comptime `_VALID_STATUS_CODES` list to 400.
  - `src/database/database.mojo` — `Database`, an in-memory `Dict[String, String]`; `delete` rebuilds a fresh dict because Mojo `Dict` has no removal method.
  - `src/config/consts.mojo` — comptime constants (`__VERSION__`, `__BASE_DIR__ = '.vortex/'`, `__DB_DIR__ = 'db/'`, `__CONFIG_FILE__`).
  - `src/file/handler.mojo` — `FileHandler`, instantiated in `main()` before the server; on startup it creates `.vortex/` and `.vortex/db/` if absent. Currently a shell (creates dirs only, no persistence wired up yet); `.vortex/` is gitignored.
- The freeform command endpoint (`POST /` and `POST /cmd`) is deliberately NOT in the stateless router; `HttpServer._dispatch_command` owns it. Request handling order: router dispatch first; only if no route matches and the method is `POST` does command dispatch run, else 404.
- Mojo 1.0 has no module-level globals or capturing closures: long-lived state lives on the server-owned struct (`Router` and `Database` are moved into `HttpServer`); config constants are `comptime`, not runtime globals.
- Data is in-memory only and resets on process restart; the `FileHandler` dirs are the only on-disk side effects so far.
- `tests/` mirrors the source packages and now covers the DB (`test_db.mojo`), HTTP request parsing (`test_parser.mojo`), and response/status serialization (`test_response.mojo`).

## Code style

- Write verbose code with no comments: never add docstrings, `#`-comments, or `//`-comments. Express intent through fully spelled-out identifiers and clear structure instead of prose.
- Verbose naming: fully spelled-out identifiers (`request`, `file_descriptor`, `bytes_received`, `index` for loop variables). No shorthand (`req`, `fd`, `buf`, `n`, `i`) except where it mirrors the libc API in `sockets.mojo`.
- Single-quoted string literals in code (including t-strings in `external_call`). Strings containing an apostrophe stay double-quoted.
- Gotcha: `mojo format` re-normalizes single-quoted literals back to double quotes. Do not run the formatter over the source (or re-apply the single-quote style afterwards).
