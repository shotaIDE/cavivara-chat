terraform {
  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "7.19.0"
    }
  }
}

resource "google_identity_platform_config" "auth" {
  provider                   = google-beta
  project                    = var.project_id
  autodelete_anonymous_users = false

  sign_in {
    allow_duplicate_emails = false

    anonymous {
      enabled = true
    }

    email {
      enabled           = false
      password_required = false
    }

    phone_number {
      enabled            = false
      test_phone_numbers = {}
    }
  }

  multi_tenant {
    allow_tenants = false
  }
}
