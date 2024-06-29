SHELL := bash

TALOS_URL  ?= 'https://github.com/siderolabs/talos/releases/download/v1.7.5/metal-amd64.iso'
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
	nix build ./router#packages.x86_64-linux.router-vm-iso

.PHONY: setup
setup: init talos-iso router-iso
	tofu apply -auto-approve

.PHONY: recreate-router
recreate-router: router-iso
	tofu taint libvirt_domain.router
	tofu apply -auto-approve

.PHONY: install-iso
install-iso:
	nix build --impure ./router#packages.x86_64-linux.install-hw-iso

.PHONY: wg-gen-keys
wg-gen-keys:
	umask 077
	mkdir -p wg
	wg genkey > wg/server.key
	wg pubkey < wg/server.key > wg/server.pub
	wg genkey > wg/client.key
	wg pubkey < wg/client.key > wg/client.pub

.PHONY: wg-conf
wg-conf:
	@echo "[Interface]"
	@echo "Address = fdcc:cafe::2/128"
	@echo "PrivateKey = $$(cat wg/client.key)"
	@echo ""
	@echo "[Peer]"
	@echo "PublicKey = $$(cat wg/server.pub)"
	@echo "Endpoint = 192.168.1.131:51820"
	@echo "AllowedIPs = fd00:dead:beef::/64"
	@echo "PersistentKeepalive = 21"

.PHONY: wg-up
wg-up:
	wg-quick up wg/wg0.conf

.PHONY: wg-down
wg-down:
	wg-quick down wg/wg0.conf


WC_NODE1 := fd00:dead:beef:0:6a1d:efff:fe45:2893

.PHONY: wc-gen
wc-gen:
	mkdir -p workload-cluster
	cd workload-cluster; \
	talosctl gen secrets; \
	talosctl gen config workload-cluster https://[$(WC_NODE1)]:6443 --with-secrets ./secrets.yaml --install-disk /dev/sdb --config-patch @../talos-machine-patch.yaml

wc-install-node1:
	cd workload-cluster; \
	talosctl apply-config --insecure -n $(WC_NODE1) -e $(WC_NODE1) --file controlplane.yaml
