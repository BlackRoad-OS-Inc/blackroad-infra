# Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
variable "railway_token" {
  description = "Railway API token"
  type        = string
  sensitive   = true
}

variable "project_id" {
  description = "Railway project ID"
  type        = string
}

variable "service_name" {
  description = "Service name within the project"
  type        = string
}
