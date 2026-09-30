# infra-azure-apim-webapp

Infraestructura como código para el reto **BankX Reactive Ledger** (NTT DATA · Tech Connect 2026).

Despliega de forma **idempotente** los recursos base en Azure mediante un script de PowerShell
ejecutado desde GitHub Actions.

## Recursos que crea

| Recurso | Nombre por defecto | Notas |
|---|---|---|
| Resource Group | `rg-cardops-demo` | Región `eastus` |
| AKS | `aks-cardops-demo` | 1 nodo `Standard_D2s_v3`, managed identity |
| Cosmos DB | `cosmos-cardops-demo` | API de MongoDB, base `bankx`, free tier |
| API Management | `apim-cardops-demo` | SKU Consumption |
| APIM API | `cardops-api` | Path `/cardops`, sin subscription key |
| APIM Backend | `placeholder-backend` | Apunta a `httpbin.org` hasta que exista el ingress |
| APIM Policy | — | `rate-limit` 100 llamadas / 60s |

## Estructura

```
.
├── .github/workflows/
│   └── deploy-infra.yml     # Pipeline: login en Azure + ejecuta deploy.ps1
├── deploy.ps1               # Script idempotente de aprovisionamiento
├── variables.ps1            # Nombres, región y subscription ID
└── README.md
```

## Requisitos previos

### 1. Providers registrados en la suscripción

El registro de providers es una operación a nivel de **suscripción**, no de resource group.
Si el Service Principal está acotado al RG, estos comandos deben ejecutarse **una sola vez**
de forma manual con una cuenta que tenga permisos sobre la suscripción:

```bash
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.ApiManagement
az provider register --namespace Microsoft.DocumentDB
```

### 2. Service Principal

```bash
SUB_ID=$(az account show --query id -o tsv)
az group create -n rg-cardops-demo -l eastus

az ad sp create-for-rbac \
  --name "sp-infra-cardops-github" \
  --role Contributor \
  --scopes /subscriptions/$SUB_ID/resourceGroups/rg-cardops-demo \
  --json-auth
```

### 3. Secreto en GitHub

El JSON completo que devuelve el comando anterior se guarda en
**Settings → Secrets and variables → Actions** con el nombre `AZURE_CREDENTIALS`.

## Ejecución

El pipeline se dispara automáticamente con un `push` a la rama **`develop`**,
o manualmente desde la pestaña **Actions → deploy-infra → Run workflow**.

## Consideraciones

- **Idempotencia**: el script verifica la existencia de cada recurso antes de crearlo,
  por lo que puede reejecutarse sin efectos secundarios.
- **Free tier de Cosmos DB**: Azure permite una sola cuenta con free tier por suscripción.
  Si ya existe otra, el despliegue falla con `Subscription is not eligible`.
- **Tiempos**: AKS tarda entre 5 y 10 minutos; APIM Consumption unos minutos más.
  El script incluye esperas explícitas y reintentos para la aplicación de la policy.
- **Soft delete de APIM**: el script purga instancias eliminadas previamente con el mismo
  nombre, ya que Azure las retiene y bloquea la recreación.

## Siguientes pasos

1. Desplegar `ingress-nginx` sobre el AKS y obtener la IP pública del LoadBalancer.
2. Reemplazar `placeholder-backend` por el ingress real.
3. Añadir la policy con `rewrite-uri` para enrutar `/cardops` → Spring Boot
   y `/quarkus` → Quarkus.
