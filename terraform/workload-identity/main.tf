variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "environment" {
  description = "Deployment environment (stg, prd)"
  type        = string
}

# GCP Service Account for Loki (GCS access)
resource "google_service_account" "loki" {
  account_id   = "loki"
  display_name = "Loki log storage SA"
  project      = var.project_id
}

resource "google_storage_bucket_iam_member" "loki_chunks" {
  bucket     = google_storage_bucket.loki_chunks.name
  role       = "roles/storage.objectAdmin"
  member     = "serviceAccount:${google_service_account.loki.email}"
  depends_on = [google_storage_bucket.loki_chunks]
}

resource "google_service_account_iam_binding" "loki_workload_identity" {
  service_account_id = google_service_account.loki.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[observability/loki-sa]"
  ]
}

# GCP Service Account for Tempo (GCS access)
resource "google_service_account" "tempo" {
  account_id   = "tempo"
  display_name = "Tempo trace storage SA"
  project      = var.project_id
}

resource "google_storage_bucket_iam_member" "tempo_traces" {
  bucket     = google_storage_bucket.tempo_traces.name
  role       = "roles/storage.objectAdmin"
  member     = "serviceAccount:${google_service_account.tempo.email}"
  depends_on = [google_storage_bucket.tempo_traces]
}

resource "google_service_account_iam_binding" "tempo_workload_identity" {
  service_account_id = google_service_account.tempo.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[observability/tempo-sa]"
  ]
}

# GCS buckets
resource "google_storage_bucket" "loki_chunks" {
  name          = "acme-loki-chunks-${var.environment}"
  location      = "ASIA-SOUTHEAST1"
  project       = var.project_id
  force_destroy = false

  lifecycle_rule {
    condition { age = 30 }
    action { type = "Delete" }
  }
}

resource "google_storage_bucket" "tempo_traces" {
  name          = "acme-tempo-traces-${var.environment}"
  location      = "ASIA-SOUTHEAST1"
  project       = var.project_id
  force_destroy = false

  lifecycle_rule {
    condition { age = 14 }
    action { type = "Delete" }
  }
}
