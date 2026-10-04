variable "aws_region" {
  description = "Região AWS padrão"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome base do projeto (usado em tags e nomes de recursos)"
  type        = string
  default     = "oficina-mecnica-lab"
}

variable "environment" {
  description = "Ambiente de execução"
  type        = string
  default     = "lab"
}

variable "db_engine_version" {
  description = "Versão do engine PostgreSQL"
  type        = string
  default     = "16"
}

variable "db_instance_class" {
  description = "Classe da instância RDS (decisão: db.t3.micro/db.t4g.micro, ver plans/00-decisoes-tecnicas.md)"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Armazenamento alocado em GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Nome do banco de dados inicial criado no RDS"
  type        = string
  default     = "oficina"
}

variable "db_username" {
  description = "Usuário administrador do banco"
  type        = string
  default     = "oficina_admin"
  sensitive   = true
}

variable "infra_state_bucket" {
  description = "Bucket S3 onde fica o state do repositório oficina-mvp-infra-iac"
  type        = string
  default     = "oficina-mvp-tfstate-536036031274"
}

variable "infra_state_key" {
  description = "Key do state do repositório oficina-mvp-infra-iac"
  type        = string
  default     = "oficina-lab/terraform.tfstate"
}
