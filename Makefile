
TOC_SCRIPT = gh-md-toc
TOC_URL = https://raw.githubusercontent.com/ekalinin/github-markdown-toc/master/$(TOC_SCRIPT)

#-------------

all: fmt doc clean

fmt:
	terraform fmt

doc:
	[ -x $(TOC_SCRIPT) ] || curl $(TOC_URL) -o $(TOC_SCRIPT)
	chmod +x $(TOC_SCRIPT)
	terraform-docs --output-file README.md markdown table .
	./$(TOC_SCRIPT) --insert README.md

check:
	shellcheck -s sh *.sh || :
	shellcheck -s sh -e SC2034 gateways/*.sh

clean:
	/bin/rm -rf $(TOC_SCRIPT) README.md.*.*

