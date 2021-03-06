#################################################################
# Makefile.in for Samba Documentation
# Authors:	
# 		James Moore <jmoore@php.net>
# 		Gerald Carter <jerry@samba.org>
# 		Jelmer Vernooij <jelmer@samba.org>

# Programs
XSLTPROC = /usr/bin/xsltproc
XMLLINT = /usr/bin/xmllint
DVIPS = /usr/bin/dvips
PNGTOPNM = /usr/bin/pngtopnm
EPSTOPNM = @EPSTOPNM@
PNMTOPNG = @PNMTOPNG@
DIA = /opt/gnome/bin/dia
PNMTOPS = /usr/bin/pnmtops
HTML2TEXT = /usr/bin/html2text
PLUCKERBUILD = /usr/bin/plucker-build
COPY_IMAGES = ./scripts/copy-images.sh
THUMBPDF = /usr/bin/thumbpdf
PDFLATEX = TEXINPUTS=xslt/latex:.: /usr/bin/pdflatex --file-line-error-style
LATEX = TEXINPUTS=xslt/latex:.: /usr/bin/latex --file-line-error-style
RM = /bin/rm
ifndef DEBUG_LATEX
PDFLATEX += --interaction nonstopmode
LATEX += --interaction nonstopmode
endif

# Paths
OUTPUTDIR = output
ARCHIVEDIR = $(OUTPUTDIR)/archive
SRCDIR = 
MANDIR = $(OUTPUTDIR)/manpages
EPSTOPDF = /usr/bin/epstopdf
MANPAGEDIR = manpages
MAKEINDEX = /usr/bin/makeindex
EXAMPLESDIR = examples
SMBDOTCONFDOC = smbdotconf
DOCBOOKDIR = tmp
PSDIR = $(OUTPUTDIR)
PDFDIR = $(OUTPUTDIR)
DVIDIR = $(OUTPUTDIR)
FODIR = $(OUTPUTDIR)
HTMLHELPDIR = $(OUTPUTDIR)/htmlhelp
VALIDATEDIR = $(OUTPUTDIR)/validate
PEARSONDIR = $(OUTPUTDIR)/pearson
TXTDIR = $(OUTPUTDIR)/textdocs
HTMLDIR=$(OUTPUTDIR)/htmldocs
PLUCKERDIR=$(OUTPUTDIR)/plucker

# Docs to build
MAIN_DOCS = $(patsubst %/index.xml,$(DOCBOOKDIR)/%.xml,$(wildcard */index.xml))
MANPAGES = $(wildcard $(MANPAGEDIR)/*.?.xml)

# Lists of files to process
LATEX_FIGURES = xslt/figures/caution.pdf xslt/figures/important.pdf xslt/figures/note.pdf xslt/figures/tip.pdf xslt/figures/warning.pdf
MANPAGES_PLUCKER = $(patsubst $(MANPAGEDIR)/%.xml,$(PLUCKERDIR)/%.pdb,$(MANPAGES_SOURCES))

help: 
	@echo "Supported make targets:"
	@echo " release - Build the docs needed for a Samba release"
	@echo " all - Build all docs that can be build using the utilities found by configure"
	@echo " everything - Build all of the above"
	@echo " pdf,tex,dvi,ps,manpages,txt,pearson,fo,htmlhelp - Build specific output format"
	@echo " html - Build multi-file HTML version of HOWTO Collection, Guide and Dev-Guide"
	@echo " html-single - Build single-file HTML version of HOWTO Collection, Guide and Dev-Guide"
	@echo " htmlman - Build HTML version of manpages"
	@echo " undocumented - Output list of undocumented smb.conf options"
	@echo " samples - Extract examples"
	@echo " files - Extract other files"

Samba-Guide/index.xml: $(subst Samba-Guide/index.xml,,$(wildcard Samba-Guide/*.xml))
howto/index.xml: $(subst howto/index.xml,,$(wildcard howto/*.xml)) howto-attributions.xml
Samba-Developers-Guide/index.xml: $(subst Samba-Developers-Guide/index.xml,,$(wildcard Samba-Developers-Guide/*.xml)) Samba-Developers-Guide-attributions.xml

# Pseudo targets 
all:   tex pdf ps html htmlhelp htmlman manpages pearson plucker verify txt
everything: manpages pdf html-single html htmlman txt ps fo htmlhelp pearson verify
release: manpages htmlman html pdf 

# Output format targets
pdf: $(patsubst $(DOCBOOKDIR)/%.xml,$(PDFDIR)/%.pdf,$(MAIN_DOCS))
dvi: $(patsubst $(DOCBOOKDIR)/%.xml,$(DVIDIR)/%.dvi,$(MAIN_DOCS))
ps: $(patsubst $(DOCBOOKDIR)/%.xml,$(PSDIR)/%.ps,$(MAIN_DOCS))
txt: $(patsubst $(DOCBOOKDIR)/%.xml,$(TXTDIR)/%.txt,$(MAIN_DOCS))
fo: $(patsubst $(DOCBOOKDIR)/%.xml,$(FODIR)/%.fo,$(MAIN_DOCS))
tex: $(patsubst $(DOCBOOKDIR)/%.xml,%.tex,$(MAIN_DOCS))
manpages: $(patsubst $(MANPAGEDIR)/%.xml,$(MANDIR)/%,$(MANPAGES)) 
pearson: $(PEARSONDIR)/howto.xml
pearson-verify: $(PEARSONDIR)/howto.report.html
plucker: $(patsubst $(DOCBOOKDIR)/%.xml,$(PLUCKERDIR)/%.pdb,$(MAIN_DOCS))
htmlman: $(patsubst $(MANPAGEDIR)/%.xml,$(HTMLDIR)/%.html,$(MANPAGES)) $(HTMLDIR)/manpages.html
html-single: $(patsubst $(DOCBOOKDIR)/%.xml,$(HTMLDIR)/%.html,$(MAIN_DOCS))
html: $(patsubst $(DOCBOOKDIR)/%.xml,$(HTMLDIR)/%/index.html,$(MAIN_DOCS)) $(HTMLDIR)/index.html
htmlhelp: $(patsubst $(DOCBOOKDIR)/%.xml,$(HTMLHELPDIR)/%,$(MAIN_DOCS))

# Intermediate docbook docs

$(DOCBOOKDIR)/%.xml: %/index.xml xslt/expand-sambadoc.xsl
	mkdir -p $(@D)
	$(XSLTPROC) --stringparam latex.imagebasedir "$*/" --stringparam noreference 1 --xinclude --output $@ xslt/expand-sambadoc.xsl $<

$(DOCBOOKDIR)/%.xml: $(MANPAGEDIR)/%.xml xslt/expand-sambadoc.xsl
	mkdir -p $(@D)
	$(XSLTPROC) --xinclude --stringparam latex.imagebasedir "$*/" --stringparam noreference 1 --output $@ xslt/expand-sambadoc.xsl $<

$(DOCBOOKDIR)/manpages.xml: $(MANPAGES_SOURCES) xslt/manpage-summary.xsl
	mkdir -p $(@D)
	echo "<article><variablelist>" > $@
	for I in $(MANPAGES_SOURCES); do $(XSLTPROC) xslt/manpage-summary.xsl $$I >> $@; done
	echo "</variablelist></article>" >> $@

# HTML docs

$(HTMLDIR)/index.html: htmldocs.html
	mkdir -p $(@D)
	cp $< $@
	
$(HTMLDIR)/%/index.html: $(DOCBOOKDIR)/%.xml $(HTMLDIR)/%/samba.css  xslt/html-chunk.xsl
	mkdir -p $(@D)
	$(XSLTPROC) --stringparam base.dir "$(HTMLDIR)/$*/" xslt/html-chunk.xsl $<
	-mkdir $(@D)/images
	$(COPY_IMAGES) html $(DOCBOOKDIR)/$*.xml $* $(@D)

# Single large HTML files
$(OUTPUTDIR)/%/samba.css: xslt/html/samba.css
	mkdir -p $(@D)
	cp $< $@

$(HTMLDIR)/%.html: $(DOCBOOKDIR)/%.xml $(HTMLDIR)/samba.css xslt/html.xsl 
	mkdir -p $(@D)/images
	$(COPY_IMAGES) html $(DOCBOOKDIR)/$*.xml $* $(@D)
	$(XSLTPROC) --output $@ xslt/html.xsl $<

%-attributions.xml: 
	echo "<para/>" > $@
	$(XSLTPROC) --xinclude xslt/generate-attributions.xsl $*/index.xml > $@

clean: 
	rm -rf $(OUTPUTDIR)/* $(DOCBOOKDIR)
	rm -f *.xml
	rm -f xslt/figures/*pdf
	rm -f $(SMBDOTCONFDOC)/parameters.*.xml
	rm -f $(patsubst $(DOCBOOKDIR)/%.xml,%.*,$(MAIN_DOCS))

# Text files
$(TXTDIR)/%.txt: $(HTMLDIR)/%.html
	mkdir -p $(@D)
	$(HTML2TEXT) -nobs -style pretty -o $@ $<

# Tex files
%.tex: $(DOCBOOKDIR)/%.xml xslt/latex.xsl
	mkdir -p $(@D)
	$(XSLTPROC) --output $@ xslt/latex.xsl $<

latexfigures: $(LATEX_FIGURES)

$(PDFDIR)/%.pdf: %.pdf
	mkdir -p $(@D)
	cp $< $@

%.idx: %.tex latexfigures
	-$(PDFLATEX) $<

%.ind: %.idx
	$(MAKEINDEX) $<

# Adobe PDF files
%.pdf: %.tex %.ind latexfigures 
	$(MAKE) $(shell $(XSLTPROC) --stringparam prepend "" --stringparam append ".png" --stringparam role latex xslt/find-image-dependencies.xsl $(DOCBOOKDIR)/$*.xml)
	-$(PDFLATEX) $<
	$(THUMBPDF) $*.pdf
	-$(PDFLATEX) $<

# DVI files
$(DVIDIR)/%.dvi: %.dvi
	mkdir -p $(@D)
	cp $< $@

%.dvi: %.tex %.idx 
	$(MAKE) $(shell $(XSLTPROC) --stringparam prepend "" --stringparam append ".eps" --stringparam role latex xslt/find-image-dependencies.xsl $(DOCBOOKDIR)/$*.xml)
	-$(LATEX) $< 

%.png: %.dia
	$(DIA) -e $@ $<

%.eps: %.png
	$(PNGTOPNM) $< | $(PNMTOPS) > $@

# PostScript files
$(PSDIR)/%.ps: $(DVIDIR)/%.dvi
	mkdir -p $(@D)
	$(DVIPS) -o $@ $<

xslt/figures/%.pdf: xslt/figures/%.eps
	$(EPSTOPDF) $<

# Fo
$(FODIR)/%.fo: $(DOCBOOKDIR)/%.xml
	mkdir -p $(@D)
	$(XSLTPROC) --output $@ http://docbook.sourceforge.net/release/xsl/current/fo/docbook.xsl $<

$(HTMLHELPDIR)/%: $(DOCBOOKDIR)/%.xml
	-mkdir -p $@/images
	$(COPY_IMAGES) html $(DOCBOOKDIR)/$*.xml $* $@
	$(XSLTPROC) --stringparam htmlhelp.chm $*.chm --stringparam manifest.in.base.dir "$@/" --stringparam base.dir "$@/" http://docbook.sourceforge.net/release/xsl/current/htmlhelp/htmlhelp.xsl $<

# Plucker docs
$(PLUCKERDIR)/%.pdb: $(HTMLDIR)/%.html $(PLUCKERDIR)
	mkdir -p $(@D)
	$(PLUCKERBUILD) -v -M1 --stayonhost  --noimages --zlib-compression -H file:$< -f $* -p $(PLUCKERDIR)

# Manpages
$(MANPAGEDIR)/smb.conf.5.xml: $(SMBDOTCONFDOC)/parameters.all.xml $(SMBDOTCONFDOC)/parameters.service.xml $(SMBDOTCONFDOC)/parameters.global.xml

$(SMBDOTCONFDOC)/parameters.all.xml: $(shell find $(SMBDOTCONFDOC) -mindepth 2 -type f -name '*.xml'  | sort -t/ -k3 | xargs) $(SMBDOTCONFDOC)/generate-file-list.sh
	$(SMBDOTCONFDOC)/generate-file-list.sh $(SMBDOTCONFDOC) > $@

$(SMBDOTCONFDOC)/parameters.global.xml: $(SMBDOTCONFDOC)/parameters.all.xml $(SMBDOTCONFDOC)/generate-context.xsl
	$(XSLTPROC) --xinclude --param smb.context "'G'" --output $(SMBDOTCONFDOC)/parameters.global.xml $(SMBDOTCONFDOC)/generate-context.xsl $<

$(SMBDOTCONFDOC)/parameters.service.xml: $(SMBDOTCONFDOC)/parameters.all.xml $(SMBDOTCONFDOC)/generate-context.xsl
	$(XSLTPROC) --xinclude --param smb.context "'S'" --output $(SMBDOTCONFDOC)/parameters.service.xml $(SMBDOTCONFDOC)/generate-context.xsl $<

$(MANDIR)/%: $(DOCBOOKDIR)/%.xml xslt/man.xsl
	mkdir -p $(@D)
	$(XSLTPROC) --output $@ xslt/man.xsl $<

# Pearson compatible XML

$(PEARSONDIR)/%.xml: %/index.xml xslt/sambadoc2pearson.xsl
	mkdir -p $(@D)
	$(XSLTPROC) --xinclude --output $@ xslt/sambadoc2pearson.xsl $<

$(PEARSONDIR)/%.report.html: $(PEARSONDIR)/%.xml
	mkdir -p $(@D)
	$(XMLLINT) --valid --noout --htmlout $< 2> $@

# Validation verification

$(VALIDATEDIR)/%.report.html: $(DOCBOOKDIR)/%.xml
	mkdir -p $(@D)
	$(XMLLINT) --valid --noout --htmlout $< 2> $@

verify: $(VALIDATEDIR)/howto.report.html $(VALIDATEDIR)/Samba-Developers-Guide.report.html $(VALIDATEDIR)/Samba-Guide.report.html 

# Find undocumented parameters

undocumented: $(SMBDOTCONFDOC)/parameters.all.xml scripts/find_missing_doc.pl scripts/find_missing_manpages.pl
	@$(PERL) scripts/find_missing_doc.pl $(SRCDIR)
	@$(PERL) scripts/find_missing_manpages.pl $(SRCDIR)

# Examples and the like

files: $(HOWTODIR)/index.xml xslt/extract-smbfiles.xsl
	$(XSLTPROC) xslt/extract-smbfiles.xsl $< > /dev/null

samples: $(DOCBOOKDIR)/howto.xml xslt/extract-examples.xsl scripts/indent-smb.conf.pl
	mkdir -p $(EXAMPLESDIR)
	$(XSLTPROC) --xinclude xslt/extract-examples.xsl $< > /dev/null 2> examples/README
	for I in examples/*.conf; do { ./scripts/indent-smb.conf.pl < $$I > $$I.tmp; mv $$I.tmp $$I; } done

# Archiving
archive: guide howto
	mkdir -p $(ARCHIVEDIR)
	cp $(PDFDIR)/howto.pdf $(ARCHIVEDIR)/TOSHARG-`date +%Y%m%d`.pdf
	cp $(PDFDIR)/Samba-Guide.pdf $(ARCHIVEDIR)/S3bE-`date +%Y%m%d`.pdf

# XSL scripts
xslt/html.xsl: xslt/html-common.xsl settings.xsl
xslt/html-chunk.xsl: xslt/html-common.xsl settings.xsl
xslt/latex.xsl: settings.xsl
xslt/expand-sambadoc.xsl: settings.xsl
xslt/generate-attributions.xsl: 
xslt/man.xsl:
xslt/pearson.xsl:

.SECONDARY:
