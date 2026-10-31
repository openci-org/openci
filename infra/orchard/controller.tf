resource "google_service_account" "controller" {
  account_id   = "orchard-controller"
  display_name = "Orchard Controller"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_compute_disk" "boot" {
  name  = "orchard-controller"
  zone  = local.zone
  type  = "pd-balanced"
  size  = 10
  image = "projects/debian-cloud/global/images/debian-12-bookworm-v20261027"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_compute_disk" "data" {
  name = "orchard-controller-data"
  zone = local.zone
  type = "pd-balanced"
  size = 10
  labels = {
    app       = "orchard"
    component = "controller"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_compute_instance" "controller" {
  name                = "orchard-controller"
  zone                = local.zone
  machine_type        = "e2-small"
  deletion_protection = true
  tags                = ["orchard-controller"]
  labels = {
    app       = "orchard"
    component = "controller"
    issue     = "g-1580"
    version   = "0-58-0"
  }

  boot_disk {
    source      = google_compute_disk.boot.id
    device_name = "persistent-disk-0"
    auto_delete = true
  }

  # Inline attachments preserve the existing non-auto-delete data disk.
  attached_disk {
    source      = google_compute_disk.data.id
    device_name = "orchard-data"
    mode        = "READ_WRITE"
  }

  network_interface {
    network    = google_compute_network.orchard.id
    subnetwork = google_compute_subnetwork.orchard.id
    network_ip = "10.77.0.2"
    stack_type = "IPV4_ONLY"

    access_config {
      nat_ip       = google_compute_address.controller.address
      network_tier = "PREMIUM"
    }
  }

  # Use metadata["startup-script"], not metadata_startup_script: the latter
  # forces VM replacement when its contents change or on an unadjusted import.
  metadata = {
    block-project-ssh-keys   = "TRUE"
    enable-oslogin           = "TRUE"
    orchard-config-version   = "projects/${local.project_id}/secrets/ORCHARD_CONTROLLER_CONFIG/versions/2"
    orchard-tailnet-firewall = file("${path.module}/tailnet-firewall.nft")
    startup-script           = file("${path.module}/startup.sh")
  }

  service_account {
    email  = google_service_account.controller.email
    scopes = ["cloud-platform"]
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  lifecycle {
    prevent_destroy = true
  }
}
