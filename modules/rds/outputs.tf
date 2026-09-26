output "endpoint" {
  description = "Endpoint (host) da instância RDS"
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Porta da instância RDS"
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Nome do banco de dados inicial"
  value       = aws_db_instance.this.db_name
}

output "secret_arn" {
  description = "ARN do segredo no Secrets Manager com a senha do banco"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "security_group_id" {
  description = "ID do Security Group do RDS"
  value       = aws_security_group.rds.id
}
