SPECFILE = grid-monitoring-config-gen.spec

#ARCH ?=`uname -i`
FILES=INSTALL README CHANGES config/ncg.conf config/ncg.localdb config/ncg.conf.example config/ncg.localdb.example config/ncg.multisite.conf config/ncg.atpvo.conf config/check_logfiles_ncg.conf
SRC=src/ncg.pl src/ncg.reload.sh 
SRCBIN=src/hashlocal-to-json.pl

rpmtopdir := $(shell rpm --eval %_topdir)
rpmbuild  := $(shell [ -x /usr/bin/rpmbuild ] && echo rpmbuild || echo rpm)

PKGNAME = $(shell grep -s '^Name:'    $(SPECFILE) | sed -e 's/Name: *//')
PKGVERS = $(shell grep -s '^Version:' $(SPECFILE) | sed -e 's/Version: *//')

distdir = dist/$(PKGNAME)-$(PKGVERS)

rpm: dist $(SPECFILE)
	mkdir -p $(rpmtopdir)/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
	cd dist && tar cvfz $(rpmtopdir)/SOURCES/$(PKGNAME)-$(PKGVERS).tgz $(PKGNAME)-$(PKGVERS)/*
	cp -f $(SPECFILE) $(rpmtopdir)/SPECS/$(SPECFILE)
	$(rpmbuild) -ba $(SPECFILE)

srpm: dist $(SPECFILE)
	mkdir -p $(rpmtopdir)/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
	cd dist && tar cvfz  $(rpmtopdir)/SOURCES/$(PKGNAME)-$(PKGVERS).tgz $(PKGNAME)-$(PKGVERS)/*
	cp -f $(SPECFILE) $(rpmtopdir)/SPECS/$(SPECFILE)
	$(rpmbuild) -bs $(SPECFILE)

sources: dist
	cd dist && tar cvfz ../$(PKGNAME)-$(PKGVERS).tgz $(PKGNAME)-$(PKGVERS)/*

dist: $(SPECFILE) $(FILES)
	mkdir -p $(distdir)/usr/sbin
	mkdir -p $(distdir)/usr/libexec
	cp -f $(SRC) $(distdir)/usr/sbin
	cp -f $(SRCBIN) $(distdir)/usr/libexec
	cp -rf config/templates $(distdir)
	cp -rf config/unicore $(distdir)
	cp -f $(FILES) $(distdir)
	cp -rf src/modules $(distdir)

clean:
	rm -rf dist
