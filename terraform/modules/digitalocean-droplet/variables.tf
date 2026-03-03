# Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
variable "name" {
  description = "Droplet name"
  type        = string
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "nyc3"
}

variable "size" {
  description = "Droplet size slug"
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "image" {
  description = "Droplet image"
  type        = string
  default     = "ubuntu-24-04-x64"
}

variable "ssh_keys" {
  description = "SSH key fingerprints"
  type        = list(string)
  default     = []
}

variable "ssh_allowed_cidr" {
  description = "CIDR blocks allowed SSH inbound. Set to your management IP range in production (e.g. [\"1.2.3.4/32\"]). Defaults to open for backward compatibility — override per environment."
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}

variable "tags" {
  description = "Additional tags"
  type        = list(string)
  default     = []
}
