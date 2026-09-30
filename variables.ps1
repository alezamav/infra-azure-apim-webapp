$RG = "rg-cardops-demo"
$LOC = "eastus"

# AKS
$AKS_NAME = "aks-cardops-demo"
$AKS_NODE_SIZE = "Standard_D2s_v3"
$AKS_NODE_COUNT = 1

# APIM
$APIM_NAME = "apim-cardops-demo"

$SUBSCRIPTION_ID = az account show --query id -o tsv

# COSMOS (Mongo API)
$COSMOS_ACCOUNT = "cosmos-cardops-demo"   # unico en Azure
$COSMOS_DB_NAME = "bankx"                 # nombre real de la base
