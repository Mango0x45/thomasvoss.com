.SILENT:
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
	printf 'SASSC\t%s\n' $<

$(outdir)/%.html: $(srcdir)/%.md
	mkdir -p `dirname "$@"`
	langdir=`echo $< | grep -o '^$(srcdir)/..'`;             \
	lastedit=`lowdown -X Last-Edited $<`;                    \
	lowdown --html-no-skiphtml --html-no-escapehtml $<       \
		| ./postproc.sed                                 \
		| cat $$langdir/head.html - $$langdir/tail.html  \
		| tac                                            \
		| sed 's/<!-- *LASTEDITED *-->/'"$$lastedit"'/'  \
		| tac >$@
	printf 'LOWDOWN\t%s\n' $<

clean:
	rm -rf $(outdir)
