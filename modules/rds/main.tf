# ==============================================================================
# SENHA DO BANCO
# ==============================================================================
# Gerada aleatoriamente e guardada no Secrets Manager (evita senha em texto
# puro em terraform.tfvars ou no state em repouso fora do backend criptografado).
#
# RESSALVA (AWS Academy Learner Lab): se a LabRole não tiver permissão para
# criar segredos no Secrets Manager, este bloco falhará no apply. Nesse caso, a
# alternativa é substituir `random_password` por uma variável sensível
# (`TF_VAR_db_password`) injetada via GitHub Secret no pipeline, e remover os
# recursos `aws_secretsmanager_secret*` abaixo. Ver plans/01-infra-db-novo-repo.md
# no repositório de specs do projeto.
# ==============================================================================

resource "random_password" "db_password" {
  length  = 24
  special = false
}

resource "aws_secretsmanager_secret" "db_password" {
  name = "${var.project_name}-rds-password"
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}

# ==============================================================================
# REDE
# ==============================================================================

resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.subnet_ids
  tags       = var.tags
}

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Libera acesso PostgreSQL (5432) somente a partir do cluster EKS"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL a partir do cluster EKS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.eks_cluster_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# ==============================================================================
# INSTÂNCIA RDS
# ==============================================================================
# multi_az = false, skip_final_snapshot = true e deletion_protection = false são
# aceitáveis aqui por ser um ambiente de estudo/lab, não produção real - reduzem
# custo e facilitam destruir/recriar durante o desenvolvimento.
# ==============================================================================

resource "aws_db_instance" "this" {
  identifier     = "${var.project_name}-postgres"
  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az                = false
  publicly_accessible     = false
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 1

  tags = var.tags
}
