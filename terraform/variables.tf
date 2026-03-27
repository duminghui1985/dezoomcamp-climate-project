variable "credentials" {
  description = "My Credentials"
  default     = "~/.credentials/google-credentials.json"
}

variable "project" {
  description = "Project ID"
  default     = "dezoomcamp-climate-project"
}

variable "region" {
  description = "Region"
  default     = "us-central1"
}

variable "location" {
  description = "Project Location"
  default     = "US"
}

variable "bq_dataset_name" {
  description = "My BigQuery Dataset Name"
  default     = "raw_climate_dataset"
}

variable "gcs_bucket_name" {
  description = "My Storage Bucket Name"
  default     = "dezoomcamp-climate-project-terra-bucket"
}

variable "gcs_storage_class" {
  description = "Bucket Storage Class"
  default     = "STANDARD"
}