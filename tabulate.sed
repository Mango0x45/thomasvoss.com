#!/bin/sed -f

# lowdown(1) works perfectly for the most part, but it annoyingly turns tab
# indentation into spaces in codeblocks.  This is a problem because we want to
# be able to use CSS to configure tab widths based on the users screen size, but
# spaces lock us into a specific indentation level.  This script solves that
# problem in a “not fool-proof but good enough for me” way.

\ <pre> ,\ </pre> {
	:loop
	s/^\(\t*\)    /\1\t/
	t loop
}
