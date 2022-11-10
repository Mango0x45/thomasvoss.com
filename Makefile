.PHONY: clean

outdir   = out
srcdir   = src
sources := $(shell find src -type f)
outputs := $(sources:.md=.html)
outputs := $(outputs:.scss=.css)
outputs := $(outputs:$(srcdir)/%=$(outdir)/%)

all: $(outputs)

$(outputs): | $(outdir)

$(outdir):
	mkdir $@

$(outdir)/%.css: $(srcdir)/%.scss
	mkdir -p `dirname "$@"`
	sassc $< >$@

$(outdir)/%.html: $(srcdir)/%.md
	mkdir -p `dirname "$@"`
	# TODO: Support other languages?
	lowdown --html-no-skiphtml --html-no-escapehtml $< \
		| cat src/en/head.html - src/en/tail.html > $@

clean:
	rm -rf $(outdir)
