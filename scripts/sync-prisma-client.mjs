#!/usr/bin/env node
/**
 * sync-prisma-client.mjs
 *
 * Copies the generated Prisma client from the repo root into the
 * Azure Functions sub-project so `func start` can resolve it.
 *
 * Run from src/api/:  node ../../scripts/sync-prisma-client.mjs
 */
import { cpSync, existsSync, mkdirSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, '..');

const pairs = [
  ['node_modules/@prisma/client', 'src/api/node_modules/@prisma/client'],
  ['node_modules/.prisma',        'src/api/node_modules/.prisma'],
];

for (const [src, dest] of pairs) {
  const srcPath  = resolve(repoRoot, src);
  const destPath = resolve(repoRoot, dest);

  if (!existsSync(srcPath)) {
    console.warn(`⚠  source not found, skipping: ${srcPath}`);
    continue;
  }

  mkdirSync(dirname(destPath), { recursive: true });
  cpSync(srcPath, destPath, { recursive: true, force: true });
  console.log(`✔  ${src} → ${dest}`);
}
