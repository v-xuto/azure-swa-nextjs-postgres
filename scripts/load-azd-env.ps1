$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")
$configPath = Join-Path $repoRoot ".azure/config.json"

if (-not (Test-Path $configPath)) {
  return
}

try {
  $config = Get-Content $configPath -Raw | ConvertFrom-Json
} catch {
  return
}

$environmentName = if ($env:AZURE_ENV_NAME) {
  $env:AZURE_ENV_NAME
} else {
  $config.defaultEnvironment
}

if (-not $environmentName) {
  return
}

$envFilePath = Join-Path $repoRoot ".azure/$environmentName/.env"
if (-not (Test-Path $envFilePath)) {
  return
}

foreach ($line in Get-Content $envFilePath) {
  if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith('#')) {
    continue
  }

  $parts = $line -split '=', 2
  if ($parts.Count -ne 2) {
    continue
  }

  $name = $parts[0].Trim()
  $value = $parts[1].Trim()
  if (-not $name) {
    continue
  }

  if ($value.Length -ge 2) {
    $startsWithDoubleQuote = $value.StartsWith('"') -and $value.EndsWith('"')
    $startsWithSingleQuote = $value.StartsWith("'") -and $value.EndsWith("'")
    if ($startsWithDoubleQuote -or $startsWithSingleQuote) {
      $value = $value.Substring(1, $value.Length - 2)
    }
  }

  if (-not (Get-Item "Env:$name" -ErrorAction SilentlyContinue)?.Value) {
    Set-Item -Path "Env:$name" -Value $value
  }
}
