# Tags comuns a todo recurso AWS deste repo (via default_tags do provider, ver provider.tf) - padrão do projeto
# (plano 11): mesmo Project nos 3 repos de Terraform, para filtrar tudo no Tag Editor com Project = oficina-mvp.
# Cada recurso ainda recebe Name + Description dizendo o que é (modules/rds).
locals {
  common_tags = {
    Project     = "oficina-mvp"
    Repository  = "oficina-mvp-infra-db"
    Component   = "banco-de-dados"
    Environment = var.environment
    ManagedBy   = "terraform"
    Course      = "FIAP POSTECH 13SOAT - Tech Challenge Fase 3"
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
}
