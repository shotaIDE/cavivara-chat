locals {
  # ID は全体合わせて 6 文字以上 30 文字以下で設定する必要があります
  # https://cloud.google.com/resource-manager/docs/creating-managing-projects?hl=ja#before_you_begin
  google_project_id_suffix           = "-cavivara-talk-dev-1"
  google_project_display_name_suffix = "-Dev-1"
  application_id_suffix              = ".CavivaraTalk.dev"
}

terraform {
  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "7.14.0"
    }
  }
}

provider "google-beta" {
  user_project_override = true
}

provider "google-beta" {
  alias                 = "no_user_project_override"
  user_project_override = false
}

module "firebase" {
  source = "../../module/firebase"

  project_id_suffix           = local.google_project_id_suffix
  project_display_name_suffix = local.google_project_display_name_suffix
  google_billing_account_id   = var.google_billing_account_id

  providers = {
    google-beta                          = google-beta
    google-beta.no_user_project_override = google-beta.no_user_project_override
  }
}

module "app" {
  source = "../../module/app"

  project_id              = module.firebase.project_id
  application_id_suffix   = local.application_id_suffix
  apple_team_id           = var.apple_team_id
  android_app_sha1_hashes = var.android_app_sha1_hashes

  depends_on = [module.firebase]
}

module "auth" {
  source = "../../module/auth"

  project_id = module.firebase.project_id

  depends_on = [module.firebase]
}

module "firestore" {
  source = "../../module/firestore"

  project_id              = module.firebase.project_id
  google_project_location = var.google_project_location
  rules_file_path         = "../../firestore.rules"

  depends_on = [module.firebase]
}
