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
2. Three are used as "Compute"-Kubernetes-Cluster.
3. Last one acts as single node "Storage"-Kubernetes-Cluster (running ceph).

## Setting up the lab (virtualizied)

```bash
make setup
make clean # to destory env
```

## Setting up the lab (physically)

Create USB with installer:
```bash
make install-iso
sudo dd if=result/iso/nixos.iso of=/dev/sdX bs=4M status=progress conv=fdatasync
```

Boot from USB and run:
```bash
sudo install-router-to-disk /dev/sdX
```


