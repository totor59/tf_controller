variable "cluster_name" {
  default = "poc-cluster"
}
variable "project_id" {
  default = "valiuz-sbx-vma"
}
variable "region" {
  default = "europe-west1"
}
variable "location" {
    default = "europe-west1-b"
}
variable "github_token" {
  type      = string
}
variable "github_org" {
  default = "totor59"
  type = string
}
variable "flux_repository" {
  default = "tf_flux"
  type = string
}
