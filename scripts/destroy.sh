#!/bin/bash
set -e

RESOURCE_GROUP="rg-cccp-poc"

echo "⚠️  Destroying CCCP Platform Infrastructure..."
echo "Resource group: $RESOURCE_GROUP"
read -p "Are you sure? (y/N) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
  az group delete --name $RESOURCE_GROUP --yes --no-wait
  echo "✅ Deletion initiated (async)"
else
  echo "❌ Cancelled"
fi
