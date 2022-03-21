# Makefile -- dispatching to dune ...

PREFIX = $(HOME)

SAMPLE = ./bbqcli.exe --help

all:
	dune build

install:
	dune install --prefix=$(PREFIX)

uninstall:
	-dune uninstall --prefix=$(PREFIX)

run:
	dune exec -- $(SAMPLE)

test:
	dune runtest

clean:
	dune clean
	rm -f *~

publish:
	git push -u github main
