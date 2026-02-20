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

variable "tags" {
  description = "Additional tags"
  type        = list(string)
  default     = []
}
