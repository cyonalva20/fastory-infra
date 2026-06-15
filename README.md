# 🏭 Fastory — Infrastructure as Code

> Plataforma SaaS multi-tenant para gestión de bodegas, desplegada en AWS con Terraform.

---

## 📐 Arquitectura de Alto Nivel

```
                        ┌──────────────────────────────────────────────┐
                        │               AWS Cloud (us-east-1)          │
                        │                                              │
  Internet              │   ┌────────────────────────────────────┐     │
     │                  │   │           VPC (10.0.0.0/16)        │     │
     ▼                  │   │                                    │     │
 ┌───────┐              │   │  ┌──────────┐    ┌──────────────┐  │     │
 │  ALB  │◄─────────────┼───┼─►│   ASG    │    │  RDS Aurora  │  │     │
 └───────┘              │   │  │ (EC2 /   │───►│  Multi-AZ    │  │     │
                        │   │  │  ECS)    │    │ (PostgreSQL) │  │     │
                        │   │  └──────────┘    └──────────────┘  │     │
                        │   │       │                             │     │
                        │   │       ▼                             │     │
                        │   │  ┌──────────┐    ┌──────────────┐  │     │
                        │   │  │   SQS    │───►│   Lambda     │  │     │
                        │   │  │ (Colas)  │    │ (Procesam.)  │  │     │
                        │   │  └──────────┘    └──────────────┘  │     │
                        │   │                                    │     │
                        │   └────────────────────────────────────┘     │
                        └──────────────────────────────────────────────┘
```

## 🧩 Componentes Principales

| Componente           | Servicio AWS       | Propósito                                      |
| -------------------- | ------------------ | ---------------------------------------------- |
| **Red**              | VPC                | Aislamiento de red con subnets públicas/privadas |
| **Cómputo**          | Auto Scaling Group | Escalado horizontal de la aplicación           |
| **Base de Datos**    | RDS Multi-AZ       | PostgreSQL con alta disponibilidad              |
| **Mensajería**       | SQS                | Colas de mensajes para procesamiento asíncrono  |
| **Procesamiento**    | Lambda             | Funciones serverless para eventos de SQS        |
| **Balanceo de Carga**| ALB                | Distribución de tráfico HTTP/HTTPS              |

## 📁 Estructura del Repositorio

```
fastory-infra/
├── .github/
│   └── workflows/
│       └── terraform.yml      # CI/CD: plan en PRs, apply en main
├── terraform/
│   ├── backend.tf             # Configuración del backend S3 + DynamoDB
│   ├── main.tf                # Provider AWS y tags globales
│   ├── variables.tf           # Variables de entrada
│   ├── outputs.tf             # Outputs globales
│   └── terraform.tfvars.example  # Plantilla de variables
├── .gitignore
└── README.md
```

## 🚀 Inicio Rápido

```bash
# 1. Clonar el repositorio
git clone https://github.com/<org>/fastory-infra.git
cd fastory-infra/terraform

# 2. Copiar y configurar variables
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars con los valores deseados

# 3. Inicializar Terraform
terraform init

# 4. Planificar cambios
terraform plan

# 5. Aplicar infraestructura
terraform apply
```

## 🔄 CI/CD Pipeline

| Evento           | Acción             | Entorno      |
| ---------------- | ------------------ | ------------ |
| Pull Request     | `terraform plan`   | —            |
| Push a `main`    | `terraform apply`  | `production` |

La autenticación con AWS se realiza mediante **OIDC** (OpenID Connect), eliminando la necesidad de access keys de larga duración.

## 🏷️ Etiquetado (Tags)

Todos los recursos creados incluyen los siguientes tags por defecto:

| Tag           | Valor        |
| ------------- | ------------ |
| `Project`     | `fastory`    |
| `Environment` | `production` |
| `ManagedBy`   | `terraform`  |

## 📄 Licencia

Uso interno — Todos los derechos reservados.