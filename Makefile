ADDONS = $(patsubst addons/%,%,$(wildcard addons/*))
TARGET = ${HOME}/Documents/Elder Scrolls Online/pts/AddOns

getESOUIID = $(shell cat addons/$(1)/.esouiid || echo "")

install: $(patsubst %,install-%,${ADDONS})
	$(info done.)

watch:
	@fswatch -o ./addons | xargs -n1 -I% $(MAKE) install

install-%: addons/%
	$(info installing $*...)
	@rsync -aC --delete "${PWD}/$</" "${TARGET}/$*"

remove: $(patsubst %,remove-%,${ADDONS})

remove-%: addons/%
	$(info uninstalling $*...)
	@rm -rf "${TARGET}/$*"

ci: $(patsubst %,ci-%,${ADDONS})

.PRECIOUS: .github/workflows/%.yml
ci-%: .github/workflows/%.yml;

.github/workflows/%.yml: .github/template.yml addons/%/.esouiid
	$(info generating CI for $*...)
	@env addonName=$* addonID=$(call getESOUIID,$*) \
		envsubst '$$addonName $$addonID' < $< > $@

release: $(patsubst %,release-%,${ADDONS})

release-%: version=$(shell grep "## Version:" addons/$*/$*.txt | cut -d' ' -f3)
release-%: addons/% dist/
	@cd addons && zip -r -9 "../dist/$*-${version}.zip" "$*" -x "$*/.*"; cd -

dist/:
	@mkdir $@
