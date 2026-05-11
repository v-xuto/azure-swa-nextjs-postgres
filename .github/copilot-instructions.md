# Copilot Instructions — azure-swa-nextjs-postgres

This app was scaffolded by `create-azure-app`. It runs on Azure Static Web Apps (frontend) + Azure Functions v4 (API) + PostgreSQL, with local dev via SWA CLI and Docker Compose.

**Stack:** Next.js · Azure Functions v4 · Prisma · PostgreSQL · Entra ID (SWA Easy Auth)

## Architecture Rules — Do Not Break These

1. **API routes at `/api/*`** — SWA proxies these to Azure Functions. Never change this prefix. New endpoints go in `src/api/src/functions/`.

2. **Azure Functions v4 pattern** — Every endpoint uses `app.http('uniqueName', { ... })`. Never use v3 `function.json` style.

3. **DB connection singleton** — Always import from `src/api/src/lib/db.ts`. Never instantiate a second client.

4. **Static export only** — The frontend uses `output: 'export'` (Next.js static export). No server-side rendering. All data fetching goes through the Azure Functions API at `/api/*`.

5. **`staticwebapp.config.json`** — Controls SWA routing and auth. You can add route rules but do not remove `navigationFallback` or `platform.apiRuntime`.
6. **Auth is header-based** — SWA injects `x-ms-client-principal` on API requests. Use `getUser()` / `requireAuth()` from `src/api/src/lib/auth.ts`. Frontend auth via `useAuth()` from `src/web/lib/auth.ts` (calls `/.auth/me`). Do not add a custom auth provider.


## Customizing This App

The template ships with a generic `User + Item` schema. Replace it with your domain:

### 1. Update the schema
Edit `db/schema.prisma` — rename or replace the `Item` model with your domain entities.

### 2. Migrate and seed
```bash
npm run db:migrate
npm run db:seed
```

### 3. Replace the API endpoints
Edit or replace `src/api/src/functions/items.ts`. Pattern for a new endpoint:

```typescript
import { app, HttpRequest, HttpResponseInit, InvocationContext } from '@azure/functions';
import db from '../lib/db.js';

app.http('myEndpoint', {
  methods: ['GET'],
  authLevel: 'anonymous',
  route: 'my-resource',
  handler: async (req: HttpRequest, ctx: InvocationContext): Promise<HttpResponseInit> => {
    return { jsonBody: { ok: true } };
  },
});
```

### 4. Replace the frontend
Edit `src/web/app/page.tsx` with your UI. All pages must be Client Components (`'use client'`) since the app uses static export.

## Files to Change

| File | Purpose |
|------|---------|
| `db/schema.prisma` | Replace `Item` with your domain entities |
| `db/seed.ts` | Replace sample data |
| `src/api/src/functions/items.ts` | Replace with your API endpoints |
| `src/web/app/page.tsx` | Replace placeholder UI |
| `src/web/app/globals.css` | Customize theme and colors |
| `src/web/app/layout.tsx` | Update page title and metadata |

## Files to Leave Alone

| File | Why |
|------|-----|
| `src/api/src/lib/db.ts` | DB singleton — a second instance causes connection leaks |
| `docker-compose.yml` | Local PostgreSQL setup |
| `src/api/host.json` | Azure Functions host config |
| `staticwebapp.config.json` | SWA routing and auth — only add rules, don't remove existing |
| `swa-cli.config.json` | Local dev proxy config |
| `infra/` | Bicep IaC — only modify to add Azure resources |
| `azure.yaml` | AZD project config |
