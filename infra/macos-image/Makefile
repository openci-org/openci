PACKER ?= packer

.PHONY: init check build

init:
	$(PACKER) init .

check:
	$(PACKER) fmt -check .
	shellcheck scripts/*.sh
	@for script in scripts/*.sh; do bash -n "$$script" || exit; done
	python3 -m json.tool toolchain.json >/dev/null
	PKR_VAR_ssh_password=validation-only $(PACKER) validate .

build: check
	mkdir -p artifacts
	TART_NO_AUTO_PRUNE=1 $(PACKER) build .
