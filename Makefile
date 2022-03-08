# Makefile -- dispatching to dune ...

SAMPLE = ./_build/default/wlanthermo.exe

all:
	dune build

run:	all
	$(SAMPLE)

test:
	dune runtest

clean:
	dune clean
	rm -f *~
