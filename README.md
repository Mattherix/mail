# My mail server

To install this mail server create a `terraform.tfvars` and a `variables.yml` file using there templated version.

You can [create a cloudflare token](https://dash.cloudflare.com/profile/api-tokens) with the Zone.DNS permission and an hetzner token in the security section of your project.

After that just run `terraform init` & `terraform apply` (on a linux host, it is using local-exec)