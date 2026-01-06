locals {
  project_id_base           = "colomney"
  project_display_name_base = "CavivaraTalk"
}

terraform {
  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "7.15.0"
      configuration_aliases = [
        google-beta.no_user_project_override
      ]
    }
  }
}

resource "google_project" "default" {
  provider = google-beta.no_user_project_override

  name            = "${local.project_display_name_base}${var.project_display_name_suffix}"
  project_id      = "${local.project_id_base}${var.project_id_suffix}"
  billing_account = var.google_billing_account_id

  labels = {}
}

resource "google_project_service" "default" {
  provider = google-beta.no_user_project_override
  project  = google_project.default.project_id
  for_each = toset([
    "cloudbilling.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudtasks.googleapis.com",
    "firebase.googleapis.com",
    "firebaserules.googleapis.com",
    "firebasestorage.googleapis.com",
    "firestore.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "identitytoolkit.googleapis.com",
    "serviceusage.googleapis.com",
    "sts.googleapis.com",
  ])
  service = each.key

  disable_on_destroy = false
}

resource "google_firebase_project" "default" {
  provider = google-beta
  project  = google_project.default.project_id

  depends_on = [
    google_project_service.default
  ]
}
