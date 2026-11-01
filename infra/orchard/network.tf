resource "google_compute_network" "orchard" {
  name                                      = "orchard"
  auto_create_subnetworks                   = false
  routing_mode                              = "REGIONAL"
  network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
  delete_default_routes_on_create           = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_compute_subnetwork" "orchard" {
  name                     = "orchard-tokyo"
  network                  = google_compute_network.orchard.id
  region                   = local.region
  ip_cidr_range            = "10.77.0.0/24"
  private_ip_google_access = true
  stack_type               = "IPV4_ONLY"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_compute_address" "controller" {
  name         = "orchard-controller-ip"
  region       = local.region
  address      = "34.146.88.213"
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"

  lifecycle {
    prevent_destroy = true
  }
}

locals {
  firewall_rules = {
    "orchard-allow-https" = {
      description   = "Public Orchard HTTPS disabled; use Direct VPC or Tailnet"
      source_ranges = ["0.0.0.0/0"]
      port          = "443"
      disabled      = true
    }
    "orchard-allow-iap-ssh" = {
      source_ranges = ["35.235.240.0/20"]
      port          = "22"
    }
    "orchard-allow-private-https" = {
      description   = "Allow Orchard HTTPS from the dedicated Direct VPC subnet; Cloud Run source tags are unsupported for ingress rules."
      source_ranges = [google_compute_subnetwork.orchard.ip_cidr_range]
      port          = "443"
    }
  }
}

resource "google_compute_firewall" "controller" {
  for_each      = local.firewall_rules
  name          = each.key
  description   = try(each.value.description, null)
  network       = google_compute_network.orchard.id
  direction     = "INGRESS"
  priority      = 1000
  disabled      = try(each.value.disabled, false)
  source_ranges = each.value.source_ranges
  target_tags   = ["orchard-controller"]

  allow {
    protocol = "tcp"
    ports    = [each.value.port]
  }
}
