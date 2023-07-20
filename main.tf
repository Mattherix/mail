terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
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
  name       = "Remote management key"
  public_key = tls_private_key.remote_management.public_key_openssh
}

resource "local_sensitive_file" "pem_file" {
  filename             = pathexpand("${var.generated_key_name}.pem")
  file_permission      = "600"
  directory_permission = "700"
  content              = tls_private_key.remote_management.private_key_openssh
}

# Step 2: Setup server
resource "hcloud_primary_ip" "mail_ipv4" {
  name          = "mail_ipv4"
  datacenter    = "fsn1-dc14"
  type          = "ipv4"
  assignee_type = "server"
  auto_delete   = true
  labels = {
    "mail" : ""
  }
}

resource "hcloud_primary_ip" "mail_ipv6" {
  name          = "mail_ipv6"
  datacenter    = "fsn1-dc14"
  type          = "ipv6"
  assignee_type = "server"
  auto_delete   = true
  labels = {
    "mail" : ""
  }
}

resource "hcloud_server" "mail" {
  name        = "mail"
  image       = "debian-12"
  server_type = "cax11"
  datacenter  = "fsn1-dc14"
  ssh_keys    = [ hcloud_ssh_key.remote_management.id ]
  backups     = true

  public_net {
    ipv4_enabled = true
    ipv4 = hcloud_primary_ip.mail_ipv4.id
    ipv6_enabled = true
    ipv6 = hcloud_primary_ip.mail_ipv6.id
  }

  labels = {
    "mail" = ""
  }
}
