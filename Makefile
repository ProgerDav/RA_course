MAKEFLAGS  := -j 1

# Recursively collect lecture sources and assets so edits to included files
# trigger a rebuild of the combined PDF. plan_images/ holds working notes
# and is excluded from the lecture build.
rwildcard = $(foreach d,$(wildcard $1*),$(if $(filter plan_images,$(notdir $d)),,$(call rwildcard,$d/,$2) $(filter $(subst *,%,$2),$d)))
LECTURE_INPUTS := $(foreach ext,tex bib png jpg jpeg pdf eps,$(call rwildcard,RA_course/lectures/,*.$(ext)))
FONT_FILES    := $(foreach ext,ttf otf txt,$(wildcard RA_course/fonts/*.$(ext)))
COURSE_ASSETS := $(wildcard RA_course/*.jpg) $(wildcard RA_course/*.jpeg) $(wildcard RA_course/*.png)

INS         = source/beamerthememetropolis.ins
PACKAGE_SRC = $(wildcard source/*.dtx)
PACKAGE_STY = $(notdir $(PACKAGE_SRC:%.dtx=%.sty))
TARGET_SRC  = RA_course/lectures.tex RA_course/references.bib $(LECTURE_INPUTS) $(FONT_FILES) $(COURSE_ASSETS)
TARGET_PDF  = RA_course/lectures.pdf
BOOKLETS_DIR = RA_course/exam_content
BOOKLETS_PDF = $(BOOKLETS_DIR)/booklets.pdf
BOOKLETS_INPUTS = $(BOOKLETS_DIR)/booklets.tex $(wildcard $(BOOKLETS_DIR)/fonts/*)
DOC_SRC     = doc/metropolistheme.dtx
DOC_PDF     = doc/metropolistheme.pdf

CTAN_CONTENT = README.md $(INS) $(PACKAGE_SRC) $(DOC_SRC) $(DOC_PDF) $(TARGET_SRC) $(TARGET_PDF)

DESTDIR     ?= $(shell kpsewhich -var-value=TEXMFHOME)
INSTALL_DIR  = $(DESTDIR)/tex/latex/metropolis
DOC_DIR      = $(DESTDIR)/doc/latex/metropolis
CACHE_DIR   := $(shell pwd)/.latex-cache

COMPILE_TEX := latexmk -xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(CACHE_DIR)
export TEXINPUTS:=$(shell pwd):$(shell pwd)/source:${TEXINPUTS}

DOCKER_IMAGE = latex-image
DOCKER_CONTAINER = latex-container

# Host `make lectures` delegates to Docker. Inside the container the same
# target runs latexmk. /.dockerenv covers `docker run ... make lectures`
# even when IN_DOCKER is not set.
IN_DOCKER ?= 0
ifneq ($(wildcard /.dockerenv),)
  IN_DOCKER := 1
endif

.PHONY: all sty doc lectures lectures-local booklets booklets-local clean install uninstall ctan clean-cache clean-sty ctan-version docker-run docker-build docker-rm

all: sty doc

sty: $(PACKAGE_STY)

doc: $(DOC_PDF)

ifeq ($(IN_DOCKER),1)
lectures: $(TARGET_PDF)
else
lectures: docker-build
	docker run --rm \
		-u "$(shell id -u):$(shell id -g)" \
		-e HOME=/tmp \
		-e IN_DOCKER=1 \
		-v "$(CURDIR)":/data \
		$(DOCKER_IMAGE) \
		make lectures
endif

lectures-local: $(TARGET_PDF)

# Prefer a local TeX installation; otherwise use the project's Docker image.
# Everything needed by the document is contained in BOOKLETS_DIR.
ifeq ($(IN_DOCKER),1)
booklets: booklets-local
else ifneq ($(shell command -v latexmk 2>/dev/null),)
booklets: booklets-local
else
booklets: docker-build
	docker run --rm \
		-u "$(shell id -u):$(shell id -g)" \
		-e HOME=/tmp \
		-e IN_DOCKER=1 \
		-v "$(CURDIR)/$(BOOKLETS_DIR)":/data \
		$(DOCKER_IMAGE) \
		latexmk -xelatex -interaction=nonstopmode -halt-on-error booklets.tex
endif

booklets-local: $(BOOKLETS_PDF)

$(BOOKLETS_PDF): $(BOOKLETS_INPUTS)
	cd $(BOOKLETS_DIR) && latexmk -xelatex -interaction=nonstopmode -halt-on-error booklets.tex

clean: clean-cache clean-sty

install: $(PACKAGE_STY) $(DOC_PDF)
	@mkdir -p $(INSTALL_DIR)
	@cp $(PACKAGE_STY) $(INSTALL_DIR)
	@mkdir -p $(DOC_DIR)
	@cp $(DOC_PDF) $(DOC_DIR)

uninstall:
	@rm -f "$(addprefix $(INSTALL_DIR)/, $(PACKAGE_STY))"
	@rmdir "$(INSTALL_DIR)"
	@rm -f "$(DOC_DIR)/$(notdir $(DOC_PDF))"
	@rmdir "$(DOC_DIR)"

clean-cache:
	@rm -rf "$(CACHE_DIR)"

clean-sty:
	@rm -f $(PACKAGE_STY)

ctan: $(CTAN_CONTENT) ctan-version
	@tar --transform "s@\(.*\)@metropolis/\1@" -cf metropolis-$(shell date "+%Y-%m-%d").tar.gz $(CTAN_CONTENT)

ctan-version:
	@sed -i 's@20[0-9][0-9]/[0-9]*/[0-9]*@$(shell date "+%Y/%m/%d")@' $(PACKAGE_SRC)

$(CACHE_DIR):
	@mkdir -p $(CACHE_DIR)

$(PACKAGE_STY): $(PACKAGE_SRC) $(INS) | clean-cache $(CACHE_DIR)
	@cd $(dir $(INS)) && latex -output-directory=$(CACHE_DIR) $(notdir $(INS))
	@cp $(addprefix $(CACHE_DIR)/,$(PACKAGE_STY)) .

$(DOC_PDF): $(DOC_SRC) $(PACKAGE_STY) | clean-cache $(CACHE_DIR)
	@cd $(dir $(DOC_SRC)) && $(COMPILE_TEX) $(notdir $(DOC_SRC))
	@cp $(CACHE_DIR)/$(notdir $(DOC_PDF)) $(DOC_PDF)

$(TARGET_PDF): $(TARGET_SRC) $(PACKAGE_STY) | clean-cache $(CACHE_DIR)
	@cd $(dir $(firstword $(TARGET_SRC))) && $(COMPILE_TEX) $(notdir $(firstword $(TARGET_SRC)))
	@cp $(CACHE_DIR)/$(notdir $(TARGET_PDF)) $(TARGET_PDF)

docker-run: docker-build
	docker run --rm -i -t \
		-u "$(shell id -u):$(shell id -g)" \
		-e HOME=/tmp \
		-e IN_DOCKER=1 \
		-v "$(CURDIR)":/data \
		--name $(DOCKER_CONTAINER) \
		$(DOCKER_IMAGE) \
		make

docker-build:
	docker build -t $(DOCKER_IMAGE) docker

docker-rm:
	docker rm $(DOCKER_CONTAINER)
