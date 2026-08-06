# ForestWatch — Secrets & Manual Setup

> Files that are gitignored for security. Copy these manually when setting up a new machine.

## Keystore (Android signing)
- **Source:** `mobile/android/app/forestwatch.keystore`
- **Alias:** `forestwatch`
- **Password:** `Gnar1al!`
- **Copy from:** previous machine or backup
- **SHA-1 fingerprints (must be registered in Google Cloud Console API key restriction):**
  - Debug: `5E:8F:16:06:2E:A3:CD:2C:4A:0D:54:78:76:BA:A6:F3:8C:AB:F6:25`
  - Release: `F9:62:C7:3A:69:A4:F5:C3:0D:A8:6B:CF:71:ED:49:46:33:D5:D1:82`

## Mobile env files
- **`mobile/.env`** (emulator): `EXPO_PUBLIC_API_URL=http://localhost:4000`
- **`mobile/.env.production`** (phone): `EXPO_PUBLIC_API_URL=http://192.168.0.111:4000`
  - Update this to the VPS API URL after deployment

## Backend env file
- **`backend/.env`** — copy from `backend/.env.example` and fill in:
  - `DATABASE_URL` — Postgres connection string
  - `JWT_SECRET` — long random string
  - `PUBLIC_URL` — public base URL for photo URLs
  - `CORS_ORIGINS` — comma-separated allowed origins

## Google Maps API Key
- **Key:** `AIzaSyA05rwJuORdp9Rvp4p0iNh2j0lHjuxK9es`
- **Already in:** `mobile/app.json` (committed, but restricted by SHA-1 in Google Cloud Console)
