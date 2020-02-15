# I configure the infrastructure for a static website:
# * Sourced from a Gitlab repository
# * Hosted from Netlify
# * Viewed from a Cloudflare subdomain (this one's disabled until production-time via comments)
# * Continuously built/deployed on git-push
#
# Run me with `terraform apply`. Maybe do a `terraform plan` first, too.
#
# To use me in a new project, just copy this file and change the `locals` block.

terraform {
  backend "s3" {
    bucket = "terraform-backend.erosson.org"
    key    = "wolcendb"
    region = "us-east-1"
  }
}

provider "cloudflare" {
  version = "~> 2.0"
}

provider "gitlab" {
  version = "~> 2.0"
}

provider "netlify" {
  version = "~> 0.4"
}

locals {
  project            = "wolcendb"
  hostdomain         = "erosson.org"
  fulldomain         = "${local.project}.${local.hostdomain}"
  cloudflare_zone_id = "7c06b35c2392935ebb0653eaf94a3e70" # erosson.org
}

resource "gitlab_project" "git" {
  name = local.project
  # description      = "https://${local.fulldomain}"
  description      = "Datamined Wolcen item and skill data. https://${local.fulldomain}"
  visibility_level = "private"
  default_branch   = "master"

  provisioner "local-exec" {
    command = <<EOF
sh -eu
git remote remove origin || true
git remote add origin ${gitlab_project.git.ssh_url_to_repo}
git push -u origin master
EOF
  }
}

# TODO the state of this one is a little screwy. Create was giving me trouble; I created by hand and imported.
module "webhost" {
  source        = "git::ssh://git@gitlab.com/erosson/terraform.git//netlify/gitlab"
  name          = gitlab_project.git.name
  custom_domain = local.fulldomain

  repo = {
    repo_branch = "master"
    command     = "yarn build:ci"
    dir         = "build"
    repo_path   = "erosson/${gitlab_project.git.name}"
  }
}

resource "cloudflare_record" "www" {
  zone_id = local.cloudflare_zone_id
  name    = local.project
  type    = "CNAME"
  value   = module.webhost.dns
  proxied = false # netlify does its own proxying
}
