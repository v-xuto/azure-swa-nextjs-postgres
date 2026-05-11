#!/usr/bin/env node
/**
 * slim-swa-api-package.mjs
 *
 * Trims non-runtime Prisma artefacts from src/api so SWA deploy
 * doesn't exceed the 100 MB limit.
 *
 * Run from repo root:  node scripts/slim-swa-api-package.mjs
 */
import { rmSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, '..');
const apiDir   = resolve(repoRoot, 'src/api');

const removePaths = [
  'node_modules/.prisma/client/libquery_engine-debian-openssl-3.0.x.so.node',
  'node_modules/.prisma/client/libquery_engine-windows.dll.node',
  'node_modules/@prisma/engines',
  'node_modules/prisma',
  'node_modules/@prisma/client/generator-build',
  // Dev dependencies – not needed at runtime
  'node_modules/typescript',
  'node_modules/@types',
];

for (const rel of removePaths) {
  const full = resolve(apiDir, rel);
  if (existsSync(full)) {
    rmSync(full, { recursive: true, force: true });
    console.log(`✔  removed ${rel}`);
  }
}
