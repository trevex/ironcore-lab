# `ironcore-lab`

## Prerequisites

```
nix # otherwise tools in direnv have to be installed manually
libvirtd # including qemu
virsh
virt-manager # optional to use a UI to interface with VMs
```

## Setup

Two networks:
1. With internet access and DHCP
2. No internet access, no DHCP

Three VMs:
1. Router (attached to both networks)
2. Compute Cluster: Single node K8s for Ironcore (attached to air-gapped network)
3. Storage Cluster: Single node K8s for Ceph (attached to air-gapped network)

