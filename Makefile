SHELL := bash

TALOS_URL  ?= 'https://github.com/siderolabs/talos/releases/download/v1.7.4/metal-amd64.iso'
TALOS_ISO  ?= build/talos-amd64.iso
ROUTER_ISO ?= result/iso/nixos.iso

ifneq ("$(wildcard $(TALOS_ISO))","")
	TALOS_CURL_ZFLAG := -z $(TALOS_ISO)
else
	TALOS_CURL_ZFLAG :=
endif

INIT_LOCK ?= .init.lock

.EXPORT_ALL_VARIABLES:

.PHONY: clean
clean:
	tofu destroy -auto-approve
	rm .init.lock
	sudo rm -rf build # requires sudo due to libvirt volumes

.PHONY: init
init: $(INIT_LOCK)
$(INIT_LOCK):
	mkdir -p build
	tofu init
	touch $(INIT_LOCK)

.PHONY: talos-iso
talos-iso: $(TALOS_ISO)
$(TALOS_ISO): init
	curl -L $(TALOS_URL) $(TALOS_CURL_ZFLAG) -o $(TALOS_ISO)

.PHONY: router-iso
router-iso: $(ROUTER_ISO)
$(ROUTER_ISO): router/flake.nix router/flake.lock
	nix build ./router#packages.x86_64-linux.iso

.PHONY: setup
setup: init talos-iso router-iso
	tofu apply -auto-approve

.PHONY: recreate-router
recreate-router: router-iso
	tofu taint libvirt_domain.router
	tofu apply -auto-approve

