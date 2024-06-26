SHELL := bash

TALOS_URL  ?= 'https://github.com/siderolabs/talos/releases/download/v1.7.5/metal-amd64.iso'
TALOS_ISO  ?= build/talos-amd64.iso
WC_NODE1 := fd00:cafe::6a1d:efff:fe45:2893

ifneq ("$(wildcard $(TALOS_ISO))","")
	TALOS_CURL_ZFLAG := -z $(TALOS_ISO)
else
	TALOS_CURL_ZFLAG :=
endif

.EXPORT_ALL_VARIABLES:


# ISOs and BUILDs

.PHONY: talos-iso
talos-iso: $(TALOS_ISO)
$(TALOS_ISO): init
	curl -L $(TALOS_URL) $(TALOS_CURL_ZFLAG) -o $(TALOS_ISO)

.PHONY: router-raw
router-raw:
	nix build --impure ./router#nixosConfigurations.router.config.formats.raw-efi

.PHONY: router-deploy
router-deploy:
	deploy ./router#router -- --impure

.PHONY: install-iso
install-iso:
	nix build --impure ./router#nixosConfigurations.installer.config.formats.iso


# Wireguard

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
	@echo "Address = fddd:cafe::2/128"
	@echo "PrivateKey = $$(cat wg/client.key)"
	@echo ""
	@echo "[Peer]"
	@echo "PublicKey = $$(cat wg/server.pub)"
	@echo "Endpoint = 192.168.1.131:51820"
	@echo "AllowedIPs = fd00:cafe::/64"
	@echo "PersistentKeepalive = 21"

.PHONY: wg-up
wg-up:
	wg-quick up wg/wg0.conf

.PHONY: wg-down
wg-down:
	wg-quick down wg/wg0.conf


# Workload-Cluster

.PHONY: wc-gen
wc-gen:
	mkdir -p workload-cluster
	cd workload-cluster; \
	talosctl gen secrets; \
	talosctl gen config workload-cluster https://[$(WC_NODE1)]:6443 --with-secrets ./secrets.yaml --install-disk /dev/sdb --config-patch @../talos-machine-patch.yaml

wc-node1-install:
	cd workload-cluster; \
	talosctl apply-config --insecure -n $(WC_NODE1) -e $(WC_NODE1) --file controlplane.yaml

wc-node1-bootstrap:
	cd workload-cluster; \
	talosctl bootstrap --talosconfig ./talosconfig -n $(WC_NODE1) -e $(WC_NODE1)

wc-node1-dmesg:
	cd workload-cluster; \
	talosctl dmesg --talosconfig ./talosconfig -n $(WC_NODE1) -e $(WC_NODE1)

wc-kubeconfig:
	cd workload-cluster; \
 	talosctl kubeconfig --talosconfig ./talosconfig  -n $(WC_NODE1) -e $(WC_NODE1)

wc-install-calico:
	kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/tigera-operator.yaml
	kubectl create -f calico-installation.yaml
