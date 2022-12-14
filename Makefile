.SILENT:
.PHONY: check clean upload-fonts

fontdir  = fonts
outdir   = out
srcdir   = src
sources := $(shell find src -type f)
outputs := $(sources:.md=.html)
outputs := $(outputs:.scss=.css)
outputs := $(outputs:$(srcdir)/%=$(outdir)/%)
outputs += $(outdir)/$(fontdir)

all: $(outputs)

$(outputs): | $(outdir)

$(outdir):
	mkdir $@
	printf 'MKDIR\t%s\n' $@

$(outdir)/$(fontdir): $(fontdir)
	cp -r $(fontdir) $(outdir)
	printf 'CP\t%s\n' $<

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

$(outdir)/%.svg: $(srcdir)/%.svg
	mkdir -p `dirname "$@"`
	cp $< $@
	printf 'CP\t%s\n' $<

check:
	find src -name '*.md' -exec \
		aspell --home-dir=./ --ignore-case check {} \;

clean:
	rm -rf $(outdir)

upload-fonts:
	rsync /usr/share/fonts/ttf-linux-libertine/LinLibertine_Rah.ttf \
		pi:/var/www/thomasvoss.com/fonts/
