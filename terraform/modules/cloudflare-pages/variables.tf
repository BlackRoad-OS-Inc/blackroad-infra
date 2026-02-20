# Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
variable "account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "project_name" {
  description = "Pages project name"
  type        = string
}

variable "build_command" {
  description = "Build command"
  type        = string
  default     = "npm run build"
}

variable "destination_dir" {
  description = "Build output directory"
  type        = string
  default     = "dist"
}

variable "environment_variables" {
  description = "Environment variables for production"
  type        = map(string)
  default     = {}
}
