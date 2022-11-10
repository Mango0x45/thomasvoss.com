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
	langdir=`echo $< | grep -o '^$(srcdir)/..'`;        \
	lowdown --html-no-skiphtml --html-no-escapehtml $<  \
		| cat $$langdir/head.html - $$langdir/tail.html > $@

clean:
	rm -rf $(outdir)
