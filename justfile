set working-directory := "./src"

default:
	just --list

build:
    pixi run mojo build main.mojo -o ../vortex

clean:
    rm -f vortex

exe:
	../vortex

mojo *args:
	pixi run mojo {{ args }}

run:
	pixi run mojo main.mojo

setup:
	pixi install

test *args:
	pixi run mojo run -I . {{ args }}

