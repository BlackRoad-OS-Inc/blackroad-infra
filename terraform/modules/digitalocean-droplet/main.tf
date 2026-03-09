# Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
resource "digitalocean_droplet" "this" {
  name       = var.name
  region     = var.region
  size       = var.size
  image      = var.image
  ssh_keys   = var.ssh_keys
  backups    = true
  monitoring = true

  tags = concat(["blackroad"], var.tags)
}

resource "digitalocean_firewall" "this" {
  name        = "${var.name}-fw"
  droplet_ids = [digitalocean_droplet.this.id]

  # SSH — restrict to known management CIDRs; override via var.ssh_allowed_cidr
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = var.ssh_allowed_cidr
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # ICMP for health checks / traceroute
  inbound_rule {
    protocol         = "icmp"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}
