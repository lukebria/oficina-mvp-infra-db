variable "project_name" {
  description = "Nome base do projeto (usado em nomes de recursos)"
  type        = string
}

variable "db_engine_version" {
  description = "Versão do engine PostgreSQL"
  type        = string
}

variable "db_instance_class" {
  description = "Classe da instância RDS"
  type        = string
}

variable "db_allocated_storage" {
  description = "Armazenamento alocado em GB"
  type        = number
}

variable "db_name" {
  description = "Nome do banco de dados inicial"
  type        = string
}

variable "db_username" {
  description = "Usuário administrador do banco"
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  description = "ID da VPC onde o RDS será criado (mesma VPC do cluster EKS)"
  type        = string
}

variable "subnet_ids" {
  description = "IDs das subnets para o DB Subnet Group (mesmas subnets do cluster EKS)"
  type        = list(string)
}

variable "eks_cluster_security_group_id" {
  description = "Security Group do cluster EKS - único a receber ingress na porta 5432"
  type        = string
}

variable "tags" {
  description = "Tags comuns aplicadas a todos os recursos"
  type        = map(string)
  default     = {}
}
