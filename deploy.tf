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
provider "aws" {
  version = "~> 2.51"
  region  = "us-east-1"
}

locals {
  project    = "wolcendb"
  hostdomain = "erosson.org"
  fulldomain = "${local.project}.${local.hostdomain}"
  # img.wolcendb.erosson.org would be nice instead of img-wolcendb.erosson.org, but cloudflare's ssl cert doesn't cover nested subdomains
  img_subdomain      = "img-${local.project}"
  imgdomain          = "${local.img_subdomain}.${local.hostdomain}"
  cloudflare_zone_id = "7c06b35c2392935ebb0653eaf94a3e70" # erosson.org
}

resource "gitlab_project" "git" {
  name = local.project
  # description      = "https://${local.fulldomain}"
  description      = "Datamined Wolcen item and skill data. https://${local.fulldomain}"
  visibility_level = "public"
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

# image hosting
resource "aws_s3_bucket" "img" {
  bucket = local.imgdomain
  acl    = "private" # avoid root directory listing; policy overrides this for image hosting
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::${local.imgdomain}/*"
            ]
        }
    ]
}
EOF
  #                "arn:aws:s3:::${local.imgdomain}/*",
  #                "arn:aws:s3:::${local.imgdomain}"
}

resource "cloudflare_record" "img" {
  zone_id = local.cloudflare_zone_id
  name    = local.img_subdomain
  type    = "CNAME"
  value   = aws_s3_bucket.img.bucket_domain_name
  proxied = true
}
