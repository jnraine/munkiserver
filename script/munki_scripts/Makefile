PKGMAKER = packagemaker
HDIUTIL = hdiutil
TMPDIR = ./build/munkiserverscripts
TARGETPATH = /etc/munki
ID = com.github.jnraine.munkiserver.clientscripts
PKG_OUT = munkiscripts.pkg
DMG_OUT = munkiscripts.dmg
TITLE = "MunkiServer Client Scripts"
FILES = postflight.rb preflight.rb
FILE_DST = postflight preflight

VERSION = $(shell date -j +"%Y%m%d")
ifeq ($(shell git rev-parse --git-dir >/dev/null 2>&1; echo $$?),0) # we are in git
	LASTCOMMITS = $(foreach var,$(FILES), $(shell git rev-list HEAD $(var) | head -n 1)) # last commit for each file
	LASTMODS = $(foreach var,$(LASTCOMMITS), $(shell git show  -s --format="%ct" $(var))"\n") # timestamp of that commit
	LASTMOD = $(shell echo $(LASTMODS) | sort -br | head -n 1) # get the newest one
	VERSION = $(shell date -j -f "%s" $(LASTMOD) +"%Y%m%d") # convert it to YYYYMMDD
	VERSION := $(strip $(VERSION))
endif
DMG2_OUT = munkiscripts-$(VERSION).dmg

all: dmg
pkg: $(PKG_OUT)
dmg: $(DMG_OUT)

$(PKG_OUT): $(FILES)
	mkdir -p $(TMPDIR)$(TARGETPATH)
	$(foreach var,$(FILES), cp $(var) $(TMPDIR)$(TARGETPATH);)
	mv $(TMPDIR)$(TARGETPATH)/postflight.rb $(TMPDIR)$(TARGETPATH)/postflight
	mv $(TMPDIR)$(TARGETPATH)/preflight.rb $(TMPDIR)$(TARGETPATH)/preflight
	sudo chown -R root:wheel $(TMPDIR)
	sudo chmod 755 $(TMPDIR)
	$(foreach var,$(FILE_DST), sudo chown root:wheel $(TMPDIR)$(TARGETPATH)/$(var);)
	$(foreach var,$(FILE_DST), sudo chmod 755 $(TMPDIR)$(TARGETPATH)/$(var);)
	$(PKGMAKER) --root $(TMPDIR) --id $(ID) --out $(PKG_OUT) --version $(VERSION) --title $(TITLE) --target 10.5 --domain system --no-recommend --discard-forks
	sudo chown -R $(LOGNAME) $(TMPDIR)
	rm -r $(TMPDIR) ./build
	
$(DMG_OUT): $(PKG_OUT)
	rm -f $(DMG_OUT) $(DMG2_OUT)
	mkdir -p $(TMPDIR)
	cp $(PKG_OUT) $(TMPDIR)
	$(HDIUTIL) create -srcfolder $(TMPDIR) $(DMG_OUT)
	rm -r $(TMPDIR) ./build
	cp $(DMG_OUT) $(DMG2_OUT)

clean:
	sudo rm -rf $(TMPDIR) ./build
	rm -f $(PKG_OUT) $(DMG_OUT)
