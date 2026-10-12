#!/usr/bin/env bash
# Plano 18: o bucket do Terraform state é por conta AWS (oficina-mvp-tfstate-<conta>), calculado das credenciais -
# assim cada integrante sobe o ambiente no próprio Learner Lab sem editar código nem gravar variables no GitHub.
# Cópia do oficina-mvp-infra-iac/scripts/state-bucket.sh. Uso: scripts/state-bucket.sh -> imprime o nome do bucket
#   --create: cria o bucket se ainda não existir (só o oficina-mvp-infra-iac, que é o primeiro a subir, usa).
set -euo pipefail
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
BUCKET="oficina-mvp-tfstate-${ACCOUNT}"
if ! aws s3api head-bucket --bucket "$BUCKET" >/dev/null 2>&1; then
  if [ "${1:-}" != "--create" ]; then
    echo "::error::Bucket de state $BUCKET não existe nesta conta. Suba o oficina-mvp-infra-iac primeiro (ele cria o bucket)." >&2
    exit 1
  fi
  aws s3api create-bucket --bucket "$BUCKET" --region us-east-1 >/dev/null
  aws s3api put-bucket-versioning --bucket "$BUCKET" --versioning-configuration Status=Enabled
  aws s3api put-public-access-block --bucket "$BUCKET" --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
  aws s3api put-bucket-tagging --bucket "$BUCKET" --tagging \
    'TagSet=[{Key=Project,Value=oficina-mvp},{Key=Name,Value=oficina-mvp-tfstate},{Key=Description,Value=Terraform state dos 3 repos de infra},{Key=ManagedBy,Value=oficina-mvp-infra-iac workflow}]'
  echo "Bucket de state criado: $BUCKET" >&2
fi
echo "$BUCKET"
