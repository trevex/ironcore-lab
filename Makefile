SHELL := bash

TALOS_URL  ?= 'https://factory.talos.dev/image/9b9d04697ed5de58fc4c774ec057175229923b9838deef77b838954829c944ab/v1.7.5/metal-amd64.iso'
TALOS_ISO  ?= build/talos-amd64.iso
WC_APISERVER_HOST := fd00:cafe::2
WC_APISERVER_PORT := 6443
WC_APISERVER := https://[$(WC_APISERVER_HOST)]:$(WC_APISERVER_PORT)
WC_NODE1 := fd00:cafe::6a1d:efff:fe45:2893
WC_NODE2 := fd00:cafe::6a1d:efff:fe3e:ee0c
WC_NODE3 := fd00:cafe::6a1d:efff:fe3f:90cc

ifneq ("$(wildcard $(TALOS_ISO))","")
	TALOS_CURL_ZFLAG := -z $(TALOS_ISO)
else
	TALOS_CURL_ZFLAG :=
endif

.EXPORT_ALL_VARIABLES:


# ISOs and BUILDs

.PHONY: talos-iso
talos-iso: $(TALOS_ISO)
$(TALOS_ISO):
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
	talosctl gen config workload-cluster $(WC_APISERVER) --with-secrets ./secrets.yaml --install-disk /dev/sdb --config-patch @../talos-machine-patch.yaml

wc-node1-install:
	cd workload-cluster; \
	talosctl apply-config --insecure -n $(WC_NODE1) -e $(WC_NODE1) --file controlplane.yaml

wc-node1-bootstrap:
	cd workload-cluster; \
	talosctl bootstrap --talosconfig ./talosconfig -n $(WC_NODE1) -e $(WC_NODE1)

wc-node1-dmesg:
	cd workload-cluster; \
	talosctl dmesg --talosconfig ./talosconfig -n $(WC_NODE1) -e $(WC_NODE1)

wc-node2-install:
	cd workload-cluster; \
	talosctl apply-config --insecure -n $(WC_NODE2) -e $(WC_NODE2) --file controlplane.yaml

wc-node3-install:
	cd workload-cluster; \
	talosctl apply-config --insecure -n $(WC_NODE3) -e $(WC_NODE3) --file controlplane.yaml

wc-kubeconfig:
	cd workload-cluster; \
 	talosctl kubeconfig --talosconfig ./talosconfig  -n $(WC_NODE1) -e $(WC_NODE1)

wc-install-calico:
	kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/tigera-operator.yaml
	kubectl create configmap -n tigera-operator kubernetes-services-endpoint --from-literal=KUBERNETES_SERVICE_HOST=$(WC_APISERVER_HOST) --from-literal=KUBERNETES_SERVICE_PORT=$(WC_APISERVER_PORT)
	kubectl create -f calico-installation.yaml

wc-install-spegel:
	kubectl create ns spegel
	kubectl label namespace spegel pod-security.kubernetes.io/enforce=privileged
	helm upgrade --namespace spegel --install --version v0.0.23 spegel oci://ghcr.io/spegel-org/helm-charts/spegel --set spegel.containerdRegistryConfigPath="/etc/cri/conf.d/hosts"
	# TODO: add toleration (for now taint was removed)




