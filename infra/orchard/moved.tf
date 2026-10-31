# Keep these mappings so older state can adopt the shared firewall definition.
moved {
  from = google_compute_firewall.public_https
  to   = google_compute_firewall.controller["orchard-allow-https"]
}

moved {
  from = google_compute_firewall.iap_ssh
  to   = google_compute_firewall.controller["orchard-allow-iap-ssh"]
}

moved {
  from = google_compute_firewall.private_https
  to   = google_compute_firewall.controller["orchard-allow-private-https"]
}
