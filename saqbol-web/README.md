# saqbol-web

Analytics dashboard for SaqBol. Next.js (App Router) + TypeScript + Tailwind v4 + Recharts.
Consumes the backend `/admin/metrics` endpoint; clients only talk to saqbol-backend.

## Run

```bash
npm install
echo 'NEXT_PUBLIC_API_BASE_URL=http://localhost:8080' > .env.local
npm run dev            # http://localhost:3000
```

Requires saqbol-backend running (with saqbol-ml behind it). Log in with an existing
account (created via the mobile app or the backend `/auth/register` endpoint).

## Structure

```
src/
  app/
    page.tsx        dashboard (protected, client component)
    login/page.tsx  login form
  components/       StatCard, CategoryChart (bar), VerdictSplit (donut)
  lib/
    config.ts       API base URL from NEXT_PUBLIC_API_BASE_URL
    api.ts          fetch wrapper: Bearer token + 401 refresh, login, fetchMetrics
    auth.ts         token storage (localStorage)
    types.ts        Overview / CategoryCount
    labels.ts       RU category labels
```

## What it shows

- KPI cards: users, total checks, scam, suspicious, alerted call sessions.
- Category distribution bar chart.
- Verdict split donut (scam / suspicious / safe).

## Next

- Admin endpoint for browsing/moderating flagged messages (needs a new backend route).
- Model version management (model_versions table).
- Recharts time series once historical metrics are collected.
