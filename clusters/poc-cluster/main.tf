module "vpc" {
  source       = "terraform-google-modules/network/google"
  version      = "9.0.0"
  project_id   = var.project_id
  network_name = "${var.cluster_name}-vnet"
  subnets = [
    {
      subnet_name   = "${var.cluster_name}-snet"
      subnet_ip     = "10.10.0.0/16"
      subnet_region = var.region
    },
  ]
  secondary_ranges = {
    "${var.cluster_name}-snet" = [
      {
        range_name    = "${var.cluster_name}-ip-range-pods"
        ip_cidr_range = "10.20.0.0/16"
      },
      {
        range_name    = "${var.cluster_name}-ip-range-services"
        ip_cidr_range = "10.30.0.0/16"
      },
    ]
  }
}

resource "google_compute_firewall" "rules" {
  project = var.project_id
  name    = "allow-ssh"
  network = module.vpc.network_name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
}

resource "google_compute_router" "router" {
  project = var.project_id
  name    = "${var.cluster_name}-nat-router"
  network = module.vpc.network_name
  region  = "europe-west1"
}

module "cloud-nat" {
  source                             = "terraform-google-modules/cloud-nat/google"
  version                            = "5.0"
  project_id                         = var.project_id
  region                             = "europe-west1"
  router                             = google_compute_router.router.name
  name                               = "${var.cluster_name}-nat-config"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}


module "gke-cluster" {
  source            = "gcs::https://www.googleapis.com/storage/v1/tf_modules/gke-cluster/gke-cluster-0.2.1.zip"
  project_id        = var.project_id
  cluster_name      = var.cluster_name
  location          = var.location
  network_name      = module.vpc.network_name
  subnetwork_name   = module.vpc.subnets_names[0]
  ip_range_pods     = module.vpc.subnets_secondary_ranges[0][0].range_name
  ip_range_services = module.vpc.subnets_secondary_ranges[0][1].range_name
  resource_labels = {
    env     = var.project_id
    cluster = var.cluster_name
  }
  node_pools = {
    "pool-1" = {
      name               = "${var.cluster_name}-pool-1"
      machine_type       = "e2-highcpu-2"
      initial_node_count = 3
      preemptible        = false
      oauth_scopes = [
        "https://www.googleapis.com/auth/compute",
        "https://www.googleapis.com/auth/devstorage.read_only",
        "https://www.googleapis.com/auth/logging.write",
        "https://www.googleapis.com/auth/monitoring",
      ]
      labels = {
        env     = var.project_id
        cluster = var.cluster_name
      }
      tags = ["pool1"]
    },
    "pool-2" = {
      name               = "${var.cluster_name}-pool-2"
      machine_type       = "e2-small"
      initial_node_count = 1
      preemptible        = false
      oauth_scopes = [
        "https://www.googleapis.com/auth/compute",
        "https://www.googleapis.com/auth/devstorage.read_only",
        "https://www.googleapis.com/auth/logging.write",
        "https://www.googleapis.com/auth/monitoring",
      ]
      labels = {
        env     = var.project_id
        cluster = var.cluster_name
      }
      tags = ["ocean--shutdown-hours-node", "${var.project_id}-gke"]
    },
  }
}


// On recup la conf GCP et la conf GKE pour kube et SpotByNetapp
data "google_client_config" "default" {}
data "google_container_cluster" "gke" {
  name       = module.gke-cluster.name
  location   = var.location
  project    = var.project_id
  depends_on = [module.gke-cluster]
}



# resource "helm_release" "spot" {
#   name = "spot-controller"

#   repository = "https://spotinst.github.io/spotinst-kubernetes-helm-charts"
#   chart      = "spotinst-kubernetes-cluster-controller"

#   set {
#     name  = "spotinst.token"
#     value = var.spotinst_token
#   }
#   set {
#     name  = "spotinst.account"
#     value = module.spotinst-gcp-connect-project.spot_account_id
#   }
#   set {
#     name = "spotinst.clusterIdentifier"
#     # value = module.ocean-gcp-k8s.ocean_controller_id
#     value = module.ocean-gcp-k8s.ocean_controller_id
#   }
#   set {
#     name  = "app.kubernetes.io/managed-by"
#     value = "Helm"
#   }
#   set {
#     name  = "meta.helm.sh/release-name"
#     value = "spot-controller"
#   }
#   set {
#     name  = "meta.helm.sh/release-namespace"
#     value = "default"
#   }
#   depends_on = [module.ocean-gcp-k8s]
# }
