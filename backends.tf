# ==============================================================================
# BACKEND CONFIGURATION
# ==============================================================================
# Reaproveita o mesmo bucket S3 de state do oficina-mvp-infra-iac (key
# separada) e a mesma tabela DynamoDB de lock (compartilhada entre os dois
# states - o LockID inclui bucket+key, então não há colisão).
#
# DEPENDÊNCIA: a tabela "oficina-mvp-infra-iac-tf-lock" precisa já existir
# (criada pela Fase 1 do bootstrap de lock em oficina-mvp-infra-iac/dynamodb.tf)
# antes do primeiro `terraform init` aqui. Ver README, seção "Como rodar
# localmente", e plans/01-infra-db-novo-repo.md no repositório de specs do
# projeto.
# ==============================================================================

terraform {
  backend "s3" {
    bucket         = "oficina-mvp-tfstate-536036031274"
    key            = "oficina-lab/db/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "oficina-mvp-infra-iac-tf-lock"
  }
}
