# Makefile -- dispatching to dune ...

SAMPLE = ./bbqcli.exe
SAMPLE = ./cli_test.exe

all:
	dune build

run:	all
	dune exec -- $(SAMPLE)

test:
	dune runtest

clean:
	dune clean
	rm -f *~
