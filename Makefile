# Makefile to build HPC Chapel lesson locally
# Docs: <https://carpentries.github.io/sandpaper-docs>

# Disable the browser, if none is set.
export R_BROWSER := $(or $(R_BROWSER),"false")

all: serve
.PHONY: all build check clean serve

serve: build
	Rscript -e "sandpaper::serve()"

build:
	Rscript -e "sandpaper::build_lesson()"

check:
	Rscript -e "sandpaper::check_lesson()"

clean:
	Rscript -e "sandpaper::reset_site()"
