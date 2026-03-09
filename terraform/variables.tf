variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Must be development, staging, or production."
  }
}

variable "agent_count" {
  description = "Target number of concurrent agents"
  type        = number
  default     = 30000
}

variable "pi_nodes" {
  description = "Raspberry Pi node IPs"
  type        = list(string)
  default     = ["192.168.4.38", "192.168.4.49"]
}

variable "gateway_url" {
  description = "BlackRoad Gateway URL"
  type        = string
  default     = "http://127.0.0.1:8787"
}
