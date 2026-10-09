set dotenv-load := true
set dotenv-required := true
set dotenv-filename := ".env.development"

default:
	just --list

setup:
	pixi install


build:
	mkdir -p .bin/
	pixi run mojo build src/main.mojo -o .bin/vortex

exe:
	./vortex

mojo *args:
	pixi run mojo {{ args }}

run:
	pixi run mojo run -I src src/main.mojo

test *args:
	pixi run mojo run -I src {{ args }}

test-all:
	@for test_file in $(find tests -name 'test_*.mojo' | sort); do pixi run mojo run -I src "$test_file" || exit 1; done

lsp-wrap:
	@if [ ! -f .pixi/envs/default/bin/mojo-lsp-server-real ]; then mv .pixi/envs/default/bin/mojo-lsp-server .pixi/envs/default/bin/mojo-lsp-server-real; fi
	@printf '%s\n' '#!/usr/bin/env bash' 'exec "$(dirname "$0")/mojo-lsp-server-real" -I "$(dirname "$0")/../../../../src" "$@"' > .pixi/envs/default/bin/mojo-lsp-server
	@chmod +x .pixi/envs/default/bin/mojo-lsp-server
	@echo 'wrapped .pixi/envs/default/bin/mojo-lsp-server with -I src'
