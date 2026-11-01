output "controller_instance" {
  value = google_compute_instance.controller.self_link
}

output "controller_private_endpoint" {
  value = "https://${google_compute_instance.controller.network_interface[0].network_ip}:443"
}

output "state_bucket" {
  value = google_storage_bucket.terraform_state.url
}
