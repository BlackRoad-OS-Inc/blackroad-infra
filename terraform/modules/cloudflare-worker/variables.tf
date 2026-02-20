# Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
variable "account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "name" {
  description = "Worker script name"
  type        = string
}

variable "script_path" {
  description = "Path to the worker script file"
  type        = string
}

variable "zone_id" {
  description = "Cloudflare zone ID for route binding"
  type        = string
  default     = ""
}

variable "route_pattern" {
  description = "URL pattern for worker route"
  type        = string
  default     = ""
}
