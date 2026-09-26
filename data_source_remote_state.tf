# ==============================================================================
# REMOTE STATE: oficina-mvp-infra-iac
# ==============================================================================
# Consome vpc_id, subnet_ids e o Security Group do cluster EKS provisionados no
# repositório oficina-mvp-infra-iac, para o RDS nascer na mesma rede e liberar
# acesso somente a partir do cluster (ver modules/rds/main.tf).
# ==============================================================================

data "terraform_remote_state" "infra" {
  backend = "s3"

  config = {
    bucket = var.infra_state_bucket
    key    = var.infra_state_key
    region = var.aws_region
  }
}
