terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "1.41.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

# Step 1: Create ssh key
resource "tls_private_key" "remote_management" {
  algorithm = "ED25519"
}

resource "hcloud_ssh_key" "remote_management" {
  name = "Remote management key"
  public_key = tls_private_key.remote_management.public_key_openssh
}

/*
output "ssh_key" {
  value = tls_private_key.remote_management.private_key_pem
  sensitive = true
}
*/

resource "local_sensitive_file" "pem_file" {
  filename = pathexpand("${var.generated_key_name}.pem")
  file_permission = "600"
  directory_permission = "700"
  content = tls_private_key.remote_management.private_key_pem
}