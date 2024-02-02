resource "google_storage_bucket" "default" {
  name          = "bucket-test1"
  force_destroy = false
  location      = "europe-west1-b"
  storage_class = "STANDARD"
}