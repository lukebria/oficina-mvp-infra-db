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
  # Lab: sem janela de recuperação. Com o default (30 dias) o nome fica reservado depois do destroy e o
  # próximo apply falha ("already scheduled for deletion") - o ambiente é recriado a cada gravação/teste.
  recovery_window_in_days = 0
  description             = "Senha do banco PostgreSQL da aplicacao (gerada pelo Terraform)"
  tags = merge(var.tags, {
    Name        = "oficina-mvp-rds-password"
    Description = "Senha do banco PostgreSQL da aplicacao (gerada pelo Terraform)"
  })
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
  tags = merge(var.tags, {
    Name        = "oficina-mvp-rds-subnets"
    Description = "Sub-redes onde o RDS da aplicacao pode rodar"
  })
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

  tags = merge(var.tags, {
    Name        = "oficina-mvp-rds-sg"
    Description = "Libera o PostgreSQL (5432) somente para o cluster EKS"
  })
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

  tags = merge(var.tags, {
    Name        = "oficina-mvp-postgres"
    Description = "Banco PostgreSQL da aplicacao (oficina-mvp-java-backend)"
  })
}
