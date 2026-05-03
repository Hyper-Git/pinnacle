module "dns" {
  source      = "./modules/dns"
  project     = var.project
  environment = var.environment
  domain_name = var.domain_name
  subdomain   = var.subdomain
}

module "networking" {
  source      = "./modules/networking"
  project     = var.project
  environment = var.environment
}

module "security" {
  source      = "./modules/security"
  project     = var.project
  environment = var.environment
  vpc_id      = module.networking.vpc_id
  github_repo = var.github_repo
}

module "database" {
  source = "./modules/database"

  project               = var.project
  environment           = var.environment
  private_subnet_ids    = module.networking.private_subnet_ids
  rds_security_group_id = module.security.rds_security_group_id
  db_name               = "pinnacle_db"
  db_username           = var.db_username
  db_password           = var.db_password
}
