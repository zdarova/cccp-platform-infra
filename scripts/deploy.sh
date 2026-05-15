#!/bin/bash
set -e

RESOURCE_GROUP="rg-cccp-poc"
LOCATION="westeurope"

echo "🚀 Deploying CCCP Platform Infrastructure..."

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION --output none

# Deploy Bicep
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file infra/main.bicep \
  --parameters pgPassword="$PG_PASSWORD" \
  --output table

echo "✅ Deployment complete!"
echo ""
echo "Outputs:"
az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name main \
  --query properties.outputs \
  --output table
