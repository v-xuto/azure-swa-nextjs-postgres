$ErrorActionPreference = "Stop"

Push-Location (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location ..
. (Join-Path (Get-Location) "scripts/load-azd-env.ps1")

Write-Host "Running database migration..."

# Always retrieve DATABASE_URL from Key Vault — never trust a locally-set value
# (Prisma auto-loads .env, so an existing DATABASE_URL would silently migrate localhost).
Write-Host "Retrieving DATABASE_URL from Key Vault..."
$env:DATABASE_URL = az keyvault secret show `
  --vault-name $env:AZURE_KEY_VAULT_NAME `
  --name "DATABASE-URL" `
  --query value -o tsv
if (-not $env:DATABASE_URL) {
  Write-Error "Failed to retrieve DATABASE_URL from Key Vault '$env:AZURE_KEY_VAULT_NAME'"
  exit 1
}

# Add a temporary firewall rule to allow this machine to reach PostgreSQL.
$myIp = (Invoke-RestMethod -Uri "https://api.ipify.org")
Write-Host "Opening firewall for $myIp..."
az postgres flexible-server firewall-rule create `
  --resource-group $env:AZURE_RESOURCE_GROUP `
  --name $env:AZURE_POSTGRESQL_SERVER_NAME `
  --rule-name "MigrationTemp" `
  --start-ip-address $myIp `
  --end-ip-address $myIp `
  --output none 2>&1

try {
  npx prisma migrate deploy --schema=db/schema.prisma
} finally {
  Write-Host "Removing temporary firewall rule..."
  az postgres flexible-server firewall-rule delete `
    --resource-group $env:AZURE_RESOURCE_GROUP `
    --name $env:AZURE_POSTGRESQL_SERVER_NAME `
    --rule-name "MigrationTemp" `
    --yes --output none 2>&1
}

Write-Host "Migration complete."
Pop-Location
