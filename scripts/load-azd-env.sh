#!/bin/bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
config_path="$repo_root/.azure/config.json"

if [ ! -f "$config_path" ]; then
  return 0
fi

if [ -n "${AZURE_ENV_NAME:-}" ]; then
  environment_name="$AZURE_ENV_NAME"
else
  environment_name="$(node -e "const fs = require('fs'); try { const config = JSON.parse(fs.readFileSync(process.argv[1], 'utf8')); if (config.defaultEnvironment) process.stdout.write(config.defaultEnvironment); } catch {}" "$config_path")"
fi

if [ -z "$environment_name" ]; then
  return 0
fi

env_file_path="$repo_root/.azure/$environment_name/.env"
if [ ! -f "$env_file_path" ]; then
  return 0
fi

while IFS='=' read -r name value; do
  if [ -z "$name" ]; then
    continue
  fi

  case "$name" in
    \#*)
      continue
      ;;
  esac

  if [ -z "${!name:-}" ]; then
    if [ "${value#\"}" != "$value" ] && [ "${value%\"}" != "$value" ]; then
      value="${value#\"}"
      value="${value%\"}"
    elif [ "${value#\'}" != "$value" ] && [ "${value%\'}" != "$value" ]; then
      value="${value#\'}"
      value="${value%\'}"
    fi

    export "$name=$value"
  fi
done < "$env_file_path"