outdir   = out
sources := $(shell find . -type f -name '*.md' -printf '%P\n')
outputs := $(addprefix $(outdir)/,$(sources:.md=.html))

all: $(outputs)

$(outputs): | $(outdir)

$(outdir):
	mkdir $@

$(outdir)/%.html: %.md
	mkdir -p `dirname "$(outdir)/$<"`
	lowdown $< | cat head.html - tail.html > $@
