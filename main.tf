terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.41.0"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "4.12.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
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
  filename             = local.private_key_path
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

  provisioner "remote-exec" {
    inline = ["sudo apt update", "sudo apt install python3 -y", "echo Done!"]

    connection {
      host        = self.ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = tls_private_key.remote_management.private_key_openssh
    }
  }
  
  provisioner "local-exec" {
    command = "ssh-keyscan -H ${self.ipv4_address} >> ~/.ssh/known_hosts && ansible-playbook -u root -i '${self.ipv4_address},' --private-key ${local.private_key_path} -e 'pub_key=${hcloud_ssh_key.remote_management.public_key}' install_mail.yml"
  }
}

# Step 3 : Reverse Dns
resource "hcloud_rdns" "mail_ipv4" {
  server_id  = hcloud_server.mail.id
  ip_address = hcloud_server.mail.ipv4_address
  dns_ptr    = local.mail_subdomain
}
resource "hcloud_rdns" "mail_ipv6" {
  server_id  = hcloud_server.mail.id
  ip_address = hcloud_server.mail.ipv6_address
  dns_ptr    = local.mail_subdomain
}

# Step 4 : DNS
resource "cloudflare_record" "mail_server_ipv4" {
  zone_id = var.cloudflare_zone_id
  name    = "mail"
  value   = hcloud_server.mail.ipv4_address
  type    = "A"
  ttl     = 3600
}
resource "cloudflare_record" "mail_server_ipv6" {
  zone_id = var.cloudflare_zone_id
  name    = "mail"
  value   = hcloud_server.mail.ipv6_address
  type    = "AAAA"
  ttl     = 3600
}