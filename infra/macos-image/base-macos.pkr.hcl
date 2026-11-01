packer {
  required_version = "= 1.16.2"
  required_plugins {
    tart = {
      source  = "github.com/cirruslabs/tart"
      version = "= 1.21.0"
    }
  }
}

variable "candidate_name" {
  type    = string
  default = "base-macos-packer-candidate"
  validation {
    condition     = can(regex("^base-macos-packer-[A-Za-z0-9][A-Za-z0-9._-]*$", var.candidate_name))
    error_message = "Use a new base-macos-packer-* name; never replace a worker's base-macos image."
  }
}

variable "ssh_password" {
  type      = string
  sensitive = true
  validation {
    condition     = length(var.ssh_password) > 0
    error_message = "Set PKR_VAR_ssh_password to the disposable guest's SSH password."
  }
}

locals {
  toolchain = jsondecode(file("${path.root}/toolchain.json"))
  environment = [
    "HOME=/Users/admin",
    "USER=admin",
    "CI=true",
    "HOMEBREW_NO_AUTO_UPDATE=1",
    "HOMEBREW_NO_ANALYTICS=1",
    "PATH=/Users/admin/fvm/default/bin:/Users/admin/.pub-cache/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin",
  ]
}

source "tart-cli" "base_macos" {
  vm_base_name                 = local.toolchain.source_image
  vm_name                      = var.candidate_name
  cpu_count                    = 4
  memory_gb                    = 8
  recovery_partition           = "keep"
  headless                     = true
  disable_vnc                  = true
  run_extra_args               = ["--no-clipboard", "--no-audio"]
  pull_concurrency             = 16
  ssh_username                 = "admin"
  ssh_password                 = var.ssh_password
  ssh_timeout                  = "10m"
  ssh_disable_agent_forwarding = true
}

build {
  sources = ["source.tart-cli.base_macos"]

  provisioner "shell" {
    inline = ["sudo -n mkdir -p /usr/local/share/openci-image", "sudo -n chown admin:staff /usr/local/share/openci-image"]
  }

  provisioner "file" {
    source      = "${path.root}/toolchain.json"
    destination = "/usr/local/share/openci-image/toolchain.json"
  }

  provisioner "shell" {
    environment_vars = local.environment
    execute_command  = "/usr/bin/env -i {{ .Vars }} /bin/bash '{{ .Path }}'"
    scripts = [
      "${path.root}/scripts/provision.sh",
      "${path.root}/scripts/verify.sh",
      "${path.root}/scripts/smoke.sh",
      "${path.root}/scripts/clean.sh",
    ]
  }

  post-processor "manifest" {
    output     = "${path.root}/artifacts/${var.candidate_name}.json"
    strip_path = true
    custom_data = {
      source_image     = local.toolchain.source_image
      toolchain_sha256 = sha256(file("${path.root}/toolchain.json"))
      candidate_name   = var.candidate_name
    }
  }
}
