set working-directory := "./src"

default:
	just --list

build:
    pixi run mojo build main.mojo -o ../vortex

clean:
    rm -f vortex

mojo *args:
	pixi run mojo {{ args }}

run:
	pixi run mojo main.mojo

test *args:
	pixi run mojo run -I . {{ args }}

