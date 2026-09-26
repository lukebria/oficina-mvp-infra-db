output "rds_endpoint" {
  description = "Endpoint (host) do RDS PostgreSQL"
  value       = module.rds.endpoint
}

output "rds_port" {
  description = "Porta do RDS PostgreSQL"
  value       = module.rds.port
}

output "rds_db_name" {
  description = "Nome do banco de dados inicial"
  value       = module.rds.db_name
}

output "rds_secret_arn" {
  description = "ARN do segredo no Secrets Manager com a senha do banco (ver README para fallback se o LabRole não permitir Secrets Manager)"
  value       = module.rds.secret_arn
}

output "rds_security_group_id" {
  description = "Security Group do RDS (libera 5432 só a partir do cluster EKS)"
  value       = module.rds.security_group_id
}
