locals {
  application_id_base = "ide.shota.colomney"
  application_id      = "${local.application_id_base}${var.application_id_suffix}"
}

terraform {
  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "7.18.0"
    }
  }
}

resource "google_firebase_apple_app" "default" {
  provider = google-beta

  project      = var.project_id
  display_name = "iOS"
  bundle_id    = local.application_id
  team_id      = var.apple_team_id
}

resource "google_firebase_android_app" "default" {
  provider = google-beta

  project      = var.project_id
  display_name = "Android"
  package_name = local.application_id
  sha1_hashes  = var.android_app_sha1_hashes
}
