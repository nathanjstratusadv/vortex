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