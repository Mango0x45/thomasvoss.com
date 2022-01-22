all:
	emacs -Q --batch -l ./scripts/build.el -f site/build 2>/dev/null
	find pub/ -name '*.html' -exec tidy -config .tidyrc -m {} + || true

clean:
	find . -regex '\./\(pub\|.*[#~]$$\)' -exec rm -rf {} +

distclean: clean
	rm -rf pkg/

publish:
	rsync -a --chown=www-data:www-data pub/ root@pi:/var/www/thomasvoss.com/pub

serve:
	simple-http-server -p 5000 pub/
