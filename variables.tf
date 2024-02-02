variable "cluster_name" {}
variable "project_id" {}
variable "region" {}
variable "location" {}
variable "network_name" {}
variable "subnetwork_name" {}
variable "spotinst_token" {}
variable "spotinst_account" {}
variable "ip_range_pods" {}
variable "ip_range_services" {}
variable "github_token" {
  type      = string
}

variable "github_org" {
  type = string
}

variable "github_repository" {
  type = string
}
