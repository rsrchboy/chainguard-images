terraform {
  required_providers {
    oci = { source = "chainguard-dev/oci" }
  }
}

variable "target_repository" {
  description = "The docker repo into which the image and attestations should be published."
}

variable "suffix" {
  default     = ""
  description = "The pushgateway component version suffix."
}

module "config" {
  source = "./config"
  name   = "prometheus-pushgateway"
  suffix = var.suffix
}

module "latest" {
  source = "../../tflib/publisher"

  name              = basename(path.module)
  target_repository = "${var.target_repository}-bitnami"
  config            = module.config.config
  build-dev         = true
}

module "test-latest" {
  source = "./tests"
  digest = module.latest.image_ref
}

resource "oci_tag" "latest" {
  depends_on = [module.test-latest]
  digest_ref = module.latest.image_ref
  tag        = "latest"
}

resource "oci_tag" "latest-dev" {
  depends_on = [module.test-latest]
  digest_ref = module.latest.dev_ref
  tag        = "latest-dev"
}
