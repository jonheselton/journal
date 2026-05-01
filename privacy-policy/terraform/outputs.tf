output "privacy_policy_url" {
  description = "The public URL of the privacy policy page"
  value       = "https://storage.googleapis.com/${google_storage_bucket.privacy_policy.name}/index.html"
}

output "bucket_name" {
  description = "The name of the GCS bucket"
  value       = google_storage_bucket.privacy_policy.name
}
