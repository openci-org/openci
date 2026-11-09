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

variable "foundation" {
  type    = string
  default = "release"
  validation {
    condition     = contains(["release", "initial", "local-initial"], var.foundation)
    error_message = "Choose release, initial, or local-initial."
  }
}

variable "ssh_password" {
  type      = string
  sensitive = true
}

locals {
  lock              = jsondecode(file("${path.root}/toolchain.json"))
  inputs            = abspath("${path.root}/../artifacts/release-0.1.7-inputs")
  foundation_digest = var.foundation == "release" ? local.lock.reference_image : local.lock.foundation_image
}

source "tart-cli" "released" {
  vm_base_name                 = var.foundation == "local-initial" ? "base-macos-release-v0.1.0" : local.foundation_digest
  vm_name                      = var.candidate_name
  cpu_count                    = 4
  memory_gb                    = 8
  disk_size_gb                 = 100
  recovery_partition           = var.foundation == "release" ? "keep" : "relocate"
  headless                     = true
  disable_vnc                  = true
  run_extra_args               = ["--no-clipboard", "--no-audio", "--dir=installers:${local.inputs}:ro"]
  ssh_username                 = "admin"
  ssh_password                 = var.ssh_password
  ssh_disable_agent_forwarding = true
  ssh_timeout                  = "10m"
}

build {
  sources = ["source.tart-cli.released"]

  provisioner "shell" {
    inline = ["sudo -n mkdir -p /usr/local/share/openci-image", "sudo -n chown -R admin:staff /usr/local/share/openci-image"]
  }

  provisioner "file" {
    source      = "${path.root}/toolchain.json"
    destination = "/usr/local/share/openci-image/toolchain.json"
  }
  provisioner "file" {
    source      = "${path.root}/codemagic-requirements.txt"
    destination = "/usr/local/share/openci-image/codemagic-requirements.txt"
  }

  provisioner "shell" {
    environment_vars = [
      "HOME=/Users/admin", "USER=admin", "CI=true",
      "OPENCI_EXPECT_RELEASE_OS=${var.foundation == "release" ? "1" : "0"}",
      "HOMEBREW_NO_AUTO_UPDATE=1", "HOMEBREW_NO_ANALYTICS=1",
      "PATH=/Users/admin/fvm/default/bin:/Users/admin/.pub-cache/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin",
    ]
    execute_command = "/usr/bin/env -i {{ .Vars }} /bin/bash '{{ .Path }}'"
    scripts = [
      "${path.root}/provision.sh",
      "${path.root}/verify.sh",
      "${path.root}/../scripts/smoke.sh",
      "${path.root}/finalize-release.sh",
      "${path.root}/../scripts/clean.sh",
    ]
  }

  post-processor "manifest" {
    output     = "${path.root}/../artifacts/${var.candidate_name}.json"
    strip_path = true
    custom_data = {
      foundation       = local.foundation_digest
      reference        = local.lock.reference_image
      toolchain_sha256 = sha256(file("${path.root}/toolchain.json"))
    }
  }
}
