terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ---------------------------------------------------------------------------
# GCS bucket – public website hosting for the privacy policy
# ---------------------------------------------------------------------------
resource "google_storage_bucket" "privacy_policy" {
  name     = "${var.project_id}-privacy-policy"
  location = var.region
  project  = var.project_id

  uniform_bucket_level_access = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "index.html"
  }

  force_destroy = true
}

# Make the bucket publicly readable
resource "google_storage_bucket_iam_member" "public_read" {
  bucket = google_storage_bucket.privacy_policy.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Upload the privacy policy HTML
resource "google_storage_bucket_object" "privacy_policy_html" {
  name         = "index.html"
  bucket       = google_storage_bucket.privacy_policy.name
  source       = "${path.module}/../index.html"
  content_type = "text/html"
}
