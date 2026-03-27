terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.16.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials)
  project     = var.project
  region      = var.region
}

# Create Google Cloud Storage Bucket (Data Lake)
resource "google_storage_bucket" "climate_bucket" {
  name          = var.gcs_bucket_name
  location      = var.location
  force_destroy = true 

  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
}

# Create BigQuery Dataset (Data Warehouse)
resource "google_bigquery_dataset" "climate_dataset" {
  dataset_id = var.bq_dataset_name
  location   = var.location
}