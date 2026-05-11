#!/bin/bash
set -e

cd "$(dirname "$0")/.."
. "$(pwd)/scripts/load-azd-env.sh"

echo "Running database migration..."

# Always retrieve DATABASE_URL from Key Vault — never trust a locally-set value
# (Prisma auto-loads .env, so an existing DATABASE_URL would silently migrate localhost).
echo "Retrieving DATABASE_URL from Key Vault..."
export DATABASE_URL=$(az keyvault secret show \
  --vault-name "$AZURE_KEY_VAULT_NAME" \
  --name "DATABASE-URL" \
  --query value -o tsv)
if [ -z "$DATABASE_URL" ]; then
  echo "ERROR: Failed to retrieve DATABASE_URL from Key Vault '$AZURE_KEY_VAULT_NAME'" >&2
  exit 1
fi

# Add a temporary firewall rule to allow this machine to reach PostgreSQL.
MY_IP=$(curl -s https://api.ipify.org)
echo "Opening firewall for $MY_IP..."
az postgres flexible-server firewall-rule create \
  --resource-group "$AZURE_RESOURCE_GROUP" \
  --name "$AZURE_POSTGRESQL_SERVER_NAME" \
  --rule-name "MigrationTemp" \
  --start-ip-address "$MY_IP" \
  --end-ip-address "$MY_IP" \
  --output none

cleanup() {
  echo "Removing temporary firewall rule..."
  az postgres flexible-server firewall-rule delete \
    --resource-group "$AZURE_RESOURCE_GROUP" \
    --name "$AZURE_POSTGRESQL_SERVER_NAME" \
    --rule-name "MigrationTemp" \
    --yes --output none
}
trap cleanup EXIT

npx prisma migrate deploy --schema=db/schema.prisma

echo "Migration complete."
