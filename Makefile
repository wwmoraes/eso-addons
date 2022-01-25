ADDONS = $(patsubst addons/%,%,$(wildcard addons/*))
TARGET = ${HOME}/Documents/Elder Scrolls Online/pts/AddOns

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

.github/workflows/%.yml: .github/template.yml
	$(info generating CI for $*...)
	@env addonName=$* envsubst '$$addonName' < $< > $@
