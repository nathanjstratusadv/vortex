default:
	just --list

setup:
	pixi install

build:
	pixi run mojo build src/main.mojo -o vortex

clean:
	rm -f vortex

exe:
	./vortex

mojo *args:
	pixi run mojo {{ args }}

run:
	pixi run mojo run -I src src/main.mojo

test *args:
	pixi run mojo run -I src {{ args }}

test-all:
	@for test_file in $(find test -name 'test_*.mojo' | sort); do pixi run mojo run -I src "$test_file" || exit 1; done
