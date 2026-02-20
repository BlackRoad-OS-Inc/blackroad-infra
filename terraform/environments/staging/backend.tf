# Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
terraform {
  backend "s3" {
    bucket                      = "blackroad-terraform-state"
    key                         = "staging/terraform.tfstate"
    region                      = "auto"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    endpoints = {
      s3 = "https://848cf0b18d51e0170e0d1537aec3505a.r2.cloudflarestorage.com"
    }
  }
}
