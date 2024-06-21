terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# Network all VMs are attached to => LAN fabric
resource "libvirt_network" "internal" {
  name = "internal-net"
  mode = "open"
  domain = "ironcore.local"
  addresses = ["fd00:dead:beef::/64"] # first address is used by host

  dns {
    enabled = false
  }

  dhcp {
    enabled = false
  }
}

# Network to model "uplink" of router
resource "libvirt_network" "uplink" {
  name = "uplink-net"
  mode = "nat"
  domain = "uplink.local"
  addresses = ["192.168.50.0/24", "fc00:cafe::/64"]

  xml {
    xslt = file("${path.root}/natipv6.xslt")
  }
}


locals {
  build_dir  = "${abspath(path.root)}/build"
  talos_iso  = "${local.build_dir}/talos-amd64.iso"
  router_iso = "${abspath(path.root)}/result/iso/nixos.iso"
}

resource "libvirt_pool" "pool" {
  name = "ironcore-vm-data"
  type = "dir"
  path = "${local.build_dir}/storage"
}

resource "libvirt_domain" "router" {
  name        = "router"
  memory      = 4096
  vcpu        = 2

  cpu {
    mode = "host-passthrough"
  }

  network_interface {
    network_name   = libvirt_network.uplink.name
    wait_for_lease = true
    addresses = ["192.168.50.50"]
  }

  network_interface {
    network_name   = libvirt_network.internal.name
    wait_for_lease = false
  }

  disk {
    file = local.router_iso
  }

  boot_device {
    dev = ["cdrom"]
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }

  tpm {
    backend_type    = "emulator"
    backend_version = "2.0"
  }
}

resource "libvirt_volume" "talos1" {
  name  = "talos1-vol"
  size  = 10 * 1024 * 1024 * 1024 # 10 GB
  pool  = libvirt_pool.pool.name
}

resource "libvirt_domain" "talos1" {
  name        = "talos1"
  memory      = 4096
  vcpu        = 2

  cpu {
    mode = "host-passthrough"
  }

  network_interface {
    network_name   = libvirt_network.internal.name
    wait_for_lease = false
  }

  disk {
    file = local.talos_iso
  }

  disk {
    volume_id = libvirt_volume.talos1.id
    scsi      = "true"
  }

  boot_device {
    dev = ["hd", "cdrom"]
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }

  tpm {
    backend_type    = "emulator"
    backend_version = "2.0"
  }

  lifecycle {
    ignore_changes = [
      disk[0].wwn,
      disk[1].wwn,
    ]
  }
}

resource "libvirt_volume" "talos2" {
  name  = "talos2-vol"
  size  = 10 * 1024 * 1024 * 1024 # 10 GB
  pool  = libvirt_pool.pool.name
}

resource "libvirt_domain" "talos2" {
  name        = "talos2"
  memory      = 4096
  vcpu        = 2

  cpu {
    mode = "host-passthrough"
  }

  network_interface {
    network_name   = libvirt_network.internal.name
    wait_for_lease = false
  }

  disk {
    # file = local.talos_iso
    file = "${abspath(path.root)}/test.iso"
  }

  disk {
    volume_id = libvirt_volume.talos2.id
    scsi      = "true"
  }

  boot_device {
    dev = ["hd", "cdrom"]
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }

  tpm {
    backend_type    = "emulator"
    backend_version = "2.0"
  }

  lifecycle {
    ignore_changes = [
      disk[0].wwn,
      disk[1].wwn,
    ]
  }
}

