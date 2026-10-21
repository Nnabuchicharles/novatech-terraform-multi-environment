module "network" {
  source            = "../../modules/network"
  project           = var.project
  environment       = var.environment
  vpc_cidr          = var.vpc_cidr
  subnet_cidr       = var.subnet_cidr
  availability_zone = var.availability_zone
}

module "security" {
  source            = "../../modules/security"
  project           = var.project
  environment       = var.environment
  vpc_id            = module.network.vpc_id
  allow_public_http = var.allow_public_http
}

module "compute" {
  count             = var.deploy_ec2 ? 1 : 0
  source            = "../../modules/compute"
  project           = var.project
  environment       = var.environment
  subnet_id         = module.network.public_subnet_id
  security_group_id = module.security.security_group_id
  instance_type     = var.instance_type
}
