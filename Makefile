
doc:
	[ -x gh-md-toc ] || curl https://raw.githubusercontent.com/ekalinin/github-markdown-toc/master/gh-md-toc -o gh-md-toc
	chmod a+x gh-md-toc
	terraform-docs --output-file README.md markdown table .
	./gh-md-toc --insert README.md

