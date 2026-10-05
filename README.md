# 🗄️ Oficina MVP — Infraestrutura do Banco de Dados Gerenciado
### Terraform do PostgreSQL via Amazon RDS (repositório 3/4 do Tech Challenge Fase 3 — POSTECH/FIAP)

---

## 📌 1. Propósito

Este repositório provisiona, via Terraform, o **banco de dados gerenciado** (Amazon RDS PostgreSQL) usado pela
aplicação principal do projeto Oficina MVP. É o repositório 3 dos 4 exigidos pelo enunciado do Tech Challenge
Fase 3 — os outros três são:

- [`oficina-auth-function`](https://github.com/lukebria/oficina-auth-function) — Lambda de autenticação por CPF/CNPJ (repositório 1/4).
- [`oficina-mvp-infra-iac`](https://github.com/lukebria/oficina-mvp-infra-iac) — infraestrutura Kubernetes: EKS, ECR, Kong (repositório 2/4).
- [`oficina-mvp-java-backend`](https://github.com/lukebria/oficina-mvp-java-backend) — aplicação principal, Spring Boot, roda no EKS (repositório 4/4).

Antes deste repositório existir, o PostgreSQL rodava como um `Deployment` comum dentro do próprio cluster EKS
(`k8s/banco.yaml`, no repo da aplicação) — sem backup gerenciado, sem alta disponibilidade nativa, e sem
nenhuma linha de Terraform. Este repositório substitui isso por um RDS de verdade.

## 🛠️ 2. Tecnologias

- **Terraform** `>= 1.5.0`, provider `hashicorp/aws ~> 5.0` e `hashicorp/random ~> 3.6`.
- **Amazon RDS PostgreSQL** (`db.t3.micro`, engine 16.x) — decisão registrada em
  `plans/00-decisoes-tecnicas.md` do repositório de specs do projeto.
- **AWS Secrets Manager** para a senha do banco (gerada aleatoriamente via `random_password`, nunca versionada
  em texto puro).
- **GitHub Actions** para CI/CD (fmt/validate → plan → apply).
- Backend do state: **S3** (bucket compartilhado com `oficina-mvp-infra-iac`) + lock via **DynamoDB** (tabela
  também compartilhada com aquele repositório).

## 🏗️ 3. Infraestrutura como Código (IaC — Terraform)

### 3.1. Estrutura de arquivos

```text
oficina-mvp-infra-db/
├── modules/
│   └── rds/
│       ├── main.tf              # aws_db_instance, security group, subnet group, senha no Secrets Manager
│       ├── variables.tf         # Variáveis do módulo RDS
│       └── outputs.tf           # Endpoint, porta, nome do banco, ARN do segredo, SG
├── backends.tf                  # Estado remoto no S3 (key própria) + lock DynamoDB compartilhado
├── provider.tf                  # Configuração dos providers (AWS ~> 5.0, random ~> 3.6)
├── data_source_remote_state.tf  # Lê vpc_id/subnet_ids/SG do cluster a partir do state do oficina-mvp-infra-iac
├── main.tf                      # Orquestração do módulo RDS
├── variables.tf                 # Variáveis globais (com defaults)
├── outputs.tf                   # Saídas consolidadas do projeto
├── .github/workflows/
│   ├── create_iac.yml           # Pipeline de fmt/validate → plan → apply
│   └── destroy_iac.yml          # Pipeline manual de destroy
└── README.md                    # Este arquivo
```

### 3.2. O que é provisionado

| Recurso | Módulo | Detalhe |
|---|---|---|
| Instância RDS | `modules/rds` | `aws_db_instance`, engine `postgres` (versão em `var.db_engine_version`), classe `db.t3.micro`, `gp3`, single-AZ, não publicamente acessível |
| Security Group do RDS | `modules/rds` | Libera porta `5432` **somente** a partir do Security Group do cluster EKS (via `terraform_remote_state`) |
| DB Subnet Group | `modules/rds` | Usa as mesmas subnets do cluster EKS (via `terraform_remote_state`) |
| Senha do banco | `modules/rds` | `random_password` + `aws_secretsmanager_secret`/`_version` — nunca em texto puro no state em repouso fora do backend criptografado nem em `.tfvars` |

### 3.3. Ambiente: AWS Academy / Vocareum Learner Lab

Mesmas restrições do repositório `oficina-mvp-infra-iac` (mesma conta de laboratório):

- Credenciais **temporárias** (access key + secret key + **session token**), expiram em poucas horas — precisam
  ser atualizadas manualmente nos GitHub Secrets sempre que a sessão do lab é renovada.
- `skip_final_snapshot = true` e `deletion_protection = false` no RDS existem para facilitar destruir/recriar o
  ambiente durante o desenvolvimento — **não** são configurações recomendadas para produção real.
- ⚠️ **Ressalva sobre Secrets Manager**: se a `LabRole` da conta não tiver permissão para criar segredos, o
  `apply` falha nos recursos `aws_secretsmanager_secret*` do módulo `rds`. Alternativa nesse caso: trocar por uma
  variável sensível (`TF_VAR_db_password`) injetada via GitHub Secret no pipeline, removendo os recursos de
  Secrets Manager — avaliar na primeira tentativa real de `apply`.
- ⚠️ **Custo do RDS no crédito do lab**: contas AWS Academy Learner Lab não são elegíveis ao Free Tier de 12
  meses das contas normais — o custo do RDS sai do crédito fixo do lab. `db.t3.micro`/single-AZ é a opção mais
  barata avaliada, mas vale acompanhar o consumo de crédito após o primeiro `apply` antes de considerar isso
  100% validado (ver `plans/01-infra-db-novo-repo.md`).

### 3.4. State remoto

Backend S3 (`backends.tf`): reaproveita o **mesmo bucket** de state do `oficina-mvp-infra-iac`
(`oficina-mvp-tfstate-536036031274`), com uma **key própria** (`oficina-lab/db/terraform.tfstate`) para não
colidir com o state daquele repositório. Lock via a **mesma tabela DynamoDB** (`oficina-mvp-infra-iac-tf-lock`) — states
diferentes não colidem porque o `LockID` inclui bucket+key.

🔗 **Dependência de ordem**: essa tabela de lock só existe depois que o `oficina-mvp-infra-iac` aplicar seu
`dynamodb.tf` (Fase 1 do bootstrap de lock daquele repositório). Rodar `terraform init` aqui **antes** disso
falha, porque o backend não consegue adquirir lock numa tabela inexistente. Ordem correta: aplicar
`oficina-mvp-infra-iac` primeiro, depois este repositório.

### 3.5. Variáveis

| Variável | Default | Descrição |
|---|---|---|
| `aws_region` | `us-east-1` | Região AWS |
| `project_name` | `oficina-mecnica-lab` | Nome base usado em tags e nomes de recursos |
| `environment` | `lab` | Ambiente, usado só como tag |
| `db_engine_version` | `16` (só a major: a AWS usa a minor default mais recente — minors antigas são retiradas, a 16.4 já não existe) | Versão do PostgreSQL |
| `db_instance_class` | `db.t3.micro` | Classe da instância RDS |
| `db_allocated_storage` | `20` | Armazenamento em GB |
| `db_name` | `oficina_mvp` | Nome do banco de dados inicial |
| `db_username` | `oficina` | Usuário administrador (sensível) |
| `infra_state_bucket` | `oficina-mvp-tfstate-536036031274` | Bucket do state do repo de infra K8s (para o remote state) |
| `infra_state_key` | `oficina-lab/terraform.tfstate` | Key do state do repo de infra K8s |

### 3.6. Outputs

| Output | Descrição |
|---|---|
| `rds_endpoint` | Host do RDS PostgreSQL |
| `rds_port` | Porta do RDS |
| `rds_db_name` | Nome do banco de dados inicial |
| `rds_secret_arn` | ARN do segredo no Secrets Manager com a senha |
| `rds_security_group_id` | Security Group do RDS |

### 3.7. Como rodar localmente

Pré-requisitos: Terraform `>= 1.5.0`, credenciais AWS ativas (AWS Academy Learner Lab: access key + secret key
+ session token), e o repositório `oficina-mvp-infra-iac` já aplicado (para a VPC/subnets/SG do cluster e a
tabela de lock existirem).

```bash
# 1. Exportar credenciais AWS da sessão atual do lab
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."
export AWS_DEFAULT_REGION="us-east-1"

# 2. Inicializar o backend remoto (S3 + lock DynamoDB compartilhado)
terraform init

# 3. Ver o que seria criado
terraform plan

# 4. Aplicar
terraform apply

# 5. Conferir o endpoint gerado
terraform output rds_endpoint
```

Para desfazer: `terraform destroy` (ou disparar manualmente o workflow `destroy_iac.yml`).

## ⚙️ 4. CI/CD (GitHub Actions)

Dois workflows, exigindo os secrets `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` / `AWS_SESSION_TOKEN` e a
variável `AWS_DEFAULT_REGION` (configurados em 2026-10-04; os 3 secrets AWS expiram a cada sessão do Learner
Lab e precisam ser regravados):

- **`create_iac.yml`** — três jobs em cadeia: `fmt-validate` (com `init -backend=false`, sem credenciais AWS) →
  `plan` → `apply`. Gatilhos de
  `pull_request`/`push` cobrem `homolog` e `master`, seguindo o git flow do projeto (`feat/* → homolog →
  master`); `apply` roda automaticamente em push para qualquer uma das duas.
- **`destroy_iac.yml`** — só dispara manualmente (`workflow_dispatch`).

**Chave de deploy — variable `DEPLOY_ENABLED`** (o crédito do AWS Academy é limitado; detalhe em
`plans/10-chave-deploy-enabled.md` no repositório de specs):
- `true` → em push para `homolog`/`master`, executa automaticamente `plan` e `apply` (deploy automático de homologação e
  produção, como pede o enunciado).
- `false` ou ausente → o pipeline roda só o que não depende da AWS e **pula** (*skipped*) `plan` e `apply`. É o estado
  padrão fora de uma janela de deploy, para um merge não subir recursos pagos.
- **Disparo manual** (*Actions → Run workflow*) ignora a chave: rodar pelo botão já é uma decisão explícita.
- Ligar/desligar: *Settings → Secrets and variables → Actions → Variables → `DEPLOY_ENABLED`*.

Regras de proteção de branch (PR obrigatório, sem commit direto em `master`) ainda **não configuradas** neste
repositório recém-criado — pendente, ver `plans/01-infra-db-novo-repo.md`.

## 🧩 5. Como este repositório se encaixa no projeto

A aplicação principal (`oficina-mvp-java-backend`) hoje se conecta a um Postgres rodando como `Deployment`
dentro do próprio cluster EKS (`k8s/banco.yaml`). Depois do primeiro `apply` bem-sucedido deste repositório, a
migração prevista é:

1. Migrar os dados existentes (roteiro completo na seção 7 abaixo), se houver algum ambiente rodando com o
   Postgres em pod.
2. Configurar a variable `DB_HOST` (GitHub, repositório `oficina-mvp-java-backend`) com o valor de
   `terraform output rds_endpoint` deste repositório — o pipeline já está preparado para isso
   (`k8s/config-secret.yaml` usa `${DB_HOST}` com fallback `banco-service`, ver README daquele repositório) —
   **não precisa editar YAML nem a pipeline**, só configurar a variable.
3. Depois de confirmar que a aplicação está saudável apontando pro RDS, remover `k8s/banco.yaml` do
   repositório da aplicação (o `Deployment`/`Service` do Postgres em pod deixam de ser necessários).

Detalhe completo em `plans/01-infra-db-novo-repo.md` (repositório de specs do projeto,
`POST-TECH/FASE-3/plans/`).

## 🔄 7. Migração de dados (Postgres em pod → RDS)

Roteiro manual — rodar depois que este repositório já tiver sido aplicado (RDS no ar) e **antes** de remover
`k8s/banco.yaml` (senão não sobra o que migrar). Usa o próprio pod do Postgres em cluster para fazer o
`pg_dump`/`pg_restore`, sem precisar expor o RDS publicamente nem instalar nada extra — o pod já está na mesma
VPC/rede que o RDS.

```bash
# 1. Descobrir o namespace e o pod do Postgres em cluster (homolog ou prod)
kubectl get pods -A -l app=banco

# 2. Abrir um shell dentro do pod (troque <namespace> e <pod> pelo que apareceu acima)
kubectl exec -it <pod> -n <namespace> -- sh

# --- a partir daqui, comandos DENTRO do pod ---

# 3. Gerar o dump do banco atual (usa a própria senha do container, já disponível como env var)
PGPASSWORD="$POSTGRES_PASSWORD" pg_dump -h localhost -U oficina -d oficina_mvp -F c -f /tmp/dump.sql

# 4. Restaurar no RDS (pegue o endpoint com `terraform output rds_endpoint` e a senha no Secrets Manager,
#    `aws secretsmanager get-secret-value --secret-id oficina-mecnica-lab-rds-password --query SecretString --output text`)
PGPASSWORD="<senha-do-rds>" pg_restore -h <rds-endpoint> -U oficina -d oficina_mvp -F c --no-owner --no-privileges /tmp/dump.sql

# 5. Sair do pod
exit
```

Depois de confirmar que os dados aparecem certos no RDS (ex: `psql` rápido contando linhas nas tabelas
principais), seguir os passos 2 e 3 da seção 6 acima (trocar `DB_HOST` e remover `k8s/banco.yaml`).

> Banco/usuário do RDS (`oficina_mvp`/`oficina`) são os mesmos do Postgres em pod e do `application.yml` da
> aplicação — alinhados de propósito, para trocar só `DB_HOST`/`DB_PASSWORD` na migração.

## 🖼️ 6. Diagrama

```mermaid
flowchart LR
    subgraph EKS["Cluster EKS (oficina-mvp-infra-iac)"]
        App["oficina-mvp-java-backend<br/>(namespaces homolog/prod)"]
        SG_EKS["Security Group do cluster"]
    end

    subgraph DB["Este repositório (oficina-mvp-infra-db)"]
        SG_RDS["Security Group do RDS<br/>(ingress só do SG do cluster)"]
        RDS[("Amazon RDS PostgreSQL<br/>db.t3.micro, single-AZ")]
        SM["AWS Secrets Manager<br/>(senha do banco)"]
    end

    App -->|"5432, dentro da VPC"| SG_RDS --> RDS
    SG_EKS -.->|"remote_state: eks_cluster_security_group_id"| SG_RDS
    RDS -.-> SM
```

> Diagrama de arquitetura específico deste repositório. Para a visão consolidada dos 4 repositórios (incluindo
> observabilidade), ver `plans/06-documentacao-arquitetural.md` no repositório de specs do projeto.
