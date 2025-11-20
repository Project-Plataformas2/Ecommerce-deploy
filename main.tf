resource "google_project_service" "gke_services" {
  for_each = toset([
    "container.googleapis.com",
    "compute.googleapis.com",
  ])

  service            = each.key
  project            = var.gcp_project_id
  disable_on_destroy = false
}

resource "google_service_account" "gke_node_sa" {
  account_id   = "gke-sa-node-${var.prefix}"
  display_name = "GKE Node Service Account"
  project      = var.gcp_project_id
}

resource "google_project_iam_member" "gke_node_sa_binding" {
  project = var.gcp_project_id
  role    = "roles/container.nodeServiceAccount"
  member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
}

resource "google_container_cluster" "gke_cluster" {
  name     = var.aks_cluster_name
  location = var.gcp_zone
  project  = var.gcp_project_id

  remove_default_node_pool = true
  initial_node_count       = 1
  deletion_protection      = false

  network    = google_compute_network.gke_vpc.self_link
  subnetwork = google_compute_subnetwork.gke_subnet.self_link

  networking_mode = "VPC_NATIVE"

  ip_allocation_policy {
    cluster_secondary_range_name  = google_compute_subnetwork.gke_subnet.secondary_ip_range[0].range_name
    services_secondary_range_name = google_compute_subnetwork.gke_subnet.secondary_ip_range[1].range_name
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }
  }

  depends_on = [
    google_project_service.gke_services,
    google_project_iam_member.gke_node_sa_binding
  ]
}

resource "google_container_node_pool" "primary_nodes" {
  name     = "primary-pool"
  location = var.gcp_zone
  cluster  = google_container_cluster.gke_cluster.name

  node_count     = 1
  node_locations = [var.gcp_zone]

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  autoscaling {
    max_node_count = 3
    min_node_count = 1
  }

  node_config {
    # Máquina liviana para bajo consumo
    machine_type = "e2-small"

    # Disco reducido para no sobrepasar 250 GB del proyecto
    disk_size_gb = 12

    # SA creada manualmente
    service_account = google_service_account.gke_node_sa.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}

