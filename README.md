# `ironcore-lab`

## Prerequisites

```
nix # otherwise tools in direnv have to be installed manually
libvirtd # including qemu
virsh
virt-manager # optional to use a UI to interface with VMs
```

## Setup

### Virtualized

Two networks:
1. With internet access and DHCP
2. No internet access, no DHCP

Three VMs:
1. Router (attached to both networks)
2. Compute Cluster: Single node K8s for Ironcore (attached to air-gapped network)
3. Storage Cluster: Single node K8s for Ceph (attached to air-gapped network)

### Physical Hardware

Five N100 MiniPC connected with a switch:
1. One is connected to LAN at home as well and acts as router.
2. Three are used as "Compute"-Kubernetes-Cluster (`cluster-1`).
3. Last one acts as single node "Storage"-Kubernetes-Cluster (running ceph) (`cluster-2`).

## Setting up the lab (virtualizied)

```bash
make setup
make clean # to destory env
```

## Setting up the lab (physically)

Create USB with installer:
```bash
make wg-gen-keys # create wireguard keys for server and client
make install-iso
sudo dd if=result/iso/nixos.iso of=/dev/sdX bs=4M status=progress conv=fdatasync
```

Boot from USB and run:
```bash
sudo install-router-to-disk /dev/sdX
```

Retrieve the wireguard-config (might need manual updates):
```bash
make wg-conf > wg/wg0.conf
```

Connect to the internal IPv6 underlay:
```bash
make wg-up
```

You should be able to ssh to the router both using the external and internal IP:
```bash
ssh test@192.168.1.131
ssh test@fd00:dead:beef::2
```

## TODO

* nixos-anywhere
* document talos image factory

