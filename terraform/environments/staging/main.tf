# Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
terraform {
  required_version = ">= 1.7"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "digitalocean" {
  token = var.digitalocean_token
}

module "gateway_pages" {
  source       = "../../modules/cloudflare-pages"
  project_name = "blackroad-gateway-staging"
  build_command = "npm run build"
  destination_dir = "dist"
  account_id   = var.cloudflare_account_id
}

module "staging_droplet" {
  source = "../../modules/digitalocean-droplet"
  name   = "blackroad-staging"
  region = var.do_region
  size   = "s-1vcpu-1gb"
  image  = "ubuntu-24-04-x64"
  ssh_keys = var.do_ssh_keys
}
