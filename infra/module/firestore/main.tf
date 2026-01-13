terraform {
  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "7.16.0"
    }
  }
}

resource "google_firestore_database" "default" {
  project                 = var.project_id
  name                    = "(default)"
  location_id             = var.google_project_location
  type                    = "FIRESTORE_NATIVE"
  delete_protection_state = "DELETE_PROTECTION_DISABLED"
  deletion_policy         = "ABANDON"
}

resource "google_firebaserules_ruleset" "firestore" {
  provider = google-beta
  project  = var.project_id
  source {
    files {
      name    = "firestore.rules"
      content = file(var.rules_file_path)
    }
  }

  depends_on = [
    google_firestore_database.default,
  ]
}

resource "google_firebaserules_release" "firestore" {
  provider     = google-beta
  name         = "cloud.firestore"
  ruleset_name = google_firebaserules_ruleset.firestore.name
  project      = var.project_id

  depends_on = [
    google_firestore_database.default,
  ]
}

resource "google_firestore_index" "house_works" {
  project    = var.project_id
  collection = "houseWorks"
  database   = google_firestore_database.default.name

  fields {
    field_path = "title"
    order      = "ASCENDING"
  }

  fields {
    field_path = "createdAt"
    order      = "DESCENDING"
  }

  depends_on = [
    google_firestore_database.default,
  ]
}

resource "google_firestore_index" "work_logs" {
  project    = var.project_id
  collection = "workLogs"
  database   = google_firestore_database.default.name

  fields {
    field_path = "title"
    order      = "ASCENDING"
  }

  fields {
    field_path = "completedAt"
    order      = "DESCENDING"
  }

  depends_on = [
    google_firestore_database.default,
  ]
}
