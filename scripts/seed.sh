#!/bin/bash
set -e

cd "$(dirname "$0")/.."
. "$(pwd)/scripts/load-azd-env.sh"

echo "🌱 Seeding Azure database..."

# Prefer DATABASE_URL if already set, otherwise retrieve from Key Vault.
if [ -z "$DATABASE_URL" ]; then
  echo "Retrieving DATABASE_URL from Key Vault..."
  export DATABASE_URL=$(az keyvault secret show \
    --vault-name "$AZURE_KEY_VAULT_NAME" \
    --name "DATABASE-URL" \
    --query value -o tsv)
fi

# Open temporary firewall rule for local machine
MY_IP=$(curl -s https://api.ipify.org)
echo "Opening firewall for $MY_IP..."
az postgres flexible-server firewall-rule create \
  --resource-group "$AZURE_RESOURCE_GROUP" \
  --name "$AZURE_POSTGRESQL_SERVER_NAME" \
  --rule-name "seed-temp-$$" \
  --start-ip-address "$MY_IP" \
  --end-ip-address "$MY_IP" 2>/dev/null || true

npx tsx db/seed.ts

# Close temporary firewall rule
echo "Closing firewall rule..."
az postgres flexible-server firewall-rule delete \
  --resource-group "$AZURE_RESOURCE_GROUP" \
  --name "$AZURE_POSTGRESQL_SERVER_NAME" \
  --rule-name "seed-temp-$$" \
  --yes 2>/dev/null || true

echo "✅ Seed complete."
