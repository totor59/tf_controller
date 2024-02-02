resource "tls_private_key" "flux" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "github_repository_deploy_key" "this" {
  title      = "Flux"
  repository = var.flux_repository
  key        = tls_private_key.flux.public_key_openssh
  read_only  = "false"
}

data "sops_file" "secrets" {
  source_file = "secrets.yaml"
}

resource "flux_bootstrap_git" "this" {
  depends_on = [github_repository_deploy_key.this]

  path = "clusters/${module.gke-cluster.name}"
}