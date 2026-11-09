PACKER ?= packer

.PHONY: init check build check-released build-released

init:
	$(PACKER) init .

check: check-released
	$(PACKER) fmt -check .
	shellcheck scripts/*.sh
	@for script in scripts/*.sh; do bash -n "$$script" || exit; done
	python3 -m json.tool toolchain.json >/dev/null
	PKR_VAR_ssh_password=validation-only $(PACKER) validate .

build: check
	mkdir -p artifacts
	TART_NO_AUTO_PRUNE=1 $(PACKER) build .

check-released:
	$(PACKER) fmt -check released
	shellcheck released/*.sh
	@for script in released/*.sh; do bash -n "$$script" || exit; done
	python3 -m json.tool released/toolchain.json >/dev/null
	python3 -c 'import ast, pathlib; ast.parse(pathlib.Path("released/prepare.py").read_text())'
	PKR_VAR_candidate_name=base-macos-packer-validation PKR_VAR_ssh_password=validation-only $(PACKER) validate "$(CURDIR)/released"

build-released: check-released
	python3 released/prepare.py $(if $(filter local-initial,$(PKR_VAR_foundation)),--local-foundation)
	TART_NO_AUTO_PRUNE=1 $(PACKER) build "$(CURDIR)/released"
