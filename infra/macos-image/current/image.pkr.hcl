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
  type = string
  validation {
    condition     = can(regex("^base-macos-packer-[A-Za-z0-9][A-Za-z0-9._-]*$", var.candidate_name))
    error_message = "Use an unused base-macos-packer-* candidate name."
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
}

source "tart-cli" "current" {
  vm_base_name                 = local.toolchain.source_image
  vm_name                      = var.candidate_name
  cpu_count                    = 4
  memory_gb                    = 8
  recovery_partition           = "keep"
  headless                     = true
  disable_vnc                  = true
  run_extra_args               = ["--no-clipboard", "--no-audio"]
  ssh_username                 = "admin"
  ssh_password                 = var.ssh_password
  ssh_timeout                  = "10m"
  ssh_disable_agent_forwarding = true
}

build {
  sources = ["source.tart-cli.current"]

  provisioner "shell" {
    inline = ["sudo -n mkdir -p /usr/local/share/openci-image", "sudo -n chown admin:staff /usr/local/share/openci-image"]
  }

  # v0.1.8 retains the v0.1.7 native toolchain and adds two Node releases.
  provisioner "file" {
    source      = "${path.root}/../released/toolchain.json"
    destination = "/usr/local/share/openci-image/toolchain.json"
  }
  provisioner "file" {
    source      = "${path.root}/toolchain.json"
    destination = "/usr/local/share/openci-image/current.json"
  }

  provisioner "shell" {
    environment_vars = [
      "HOME=/Users/admin", "USER=admin", "CI=true",
      "OPENCI_EXPECT_RELEASE_OS=1",
      "HOMEBREW_NO_AUTO_UPDATE=1", "HOMEBREW_NO_ANALYTICS=1",
      "PATH=/Users/admin/fvm/default/bin:/Users/admin/.pub-cache/bin:/Users/admin/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin",
    ]
    execute_command = "/usr/bin/env -i {{ .Vars }} /bin/bash '{{ .Path }}'"
    scripts = [
      "${path.root}/provision.sh",
      "${path.root}/../released/verify.sh",
      "${path.root}/verify.sh",
      "${path.root}/../scripts/clean.sh",
    ]
  }

  post-processor "manifest" {
    output     = "${path.root}/../artifacts/${var.candidate_name}.json"
    strip_path = true
    custom_data = {
      source_image          = local.toolchain.source_image
      target_release        = local.toolchain.target_release
      toolchain_sha256      = sha256(file("${path.root}/toolchain.json"))
      native_toolchain_hash = sha256(file("${path.root}/../released/toolchain.json"))
      patrol_cli_version    = local.toolchain.patrol_cli_version
    }
  }
}
