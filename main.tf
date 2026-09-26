locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# Chamada do Módulo RDS (PostgreSQL gerenciado)
module "rds" {
  source = "./modules/rds"

  project_name         = var.project_name
  db_engine_version    = var.db_engine_version
  db_instance_class    = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  db_name              = var.db_name
  db_username          = var.db_username

  vpc_id                        = data.terraform_remote_state.infra.outputs.vpc_id
  subnet_ids                    = data.terraform_remote_state.infra.outputs.subnet_ids
  eks_cluster_security_group_id = data.terraform_remote_state.infra.outputs.eks_cluster_security_group_id

  tags = local.common_tags
}
