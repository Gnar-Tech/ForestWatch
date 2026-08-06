# ForestWatch — Agent Guide

> **Read this file first.** It contains everything needed to continue development on any machine with zero gaps.

## Project Overview

ForestWatch is a forest monitoring app for reporting illegal dump sites. Users photograph and geotag dump sites from a mobile app; volunteers can report cleanup activity via the website.

## Architecture

Three components:

### 1. Backend (`/backend`)
- **Stack:** Node.js + TypeScript + Express + PostgreSQL/PostGIS
- **Port:** 4000
- **Key files:**
  - `src/index.ts` — entry point, runs migrations then starts server
  - `src/app.ts` — Express app factory, CORS, routes, error handler
  - `src/config.ts` — env-based config (DATABASE_URL, JWT_SECRET, PUBLIC_URL, CORS_ORIGINS)
  - `src/db/schema.sql` — idempotent schema (volunteers, dump_sites, cleanup_reports + PostGIS geom column/trigger)
  - `src/db/migrate.ts` — runs schema.sql on startup
  - `src/db/pool.ts` — pg Pool + query/queryOne helpers
  - `src/routes/auth.routes.ts` — volunteer auth (register/login, JWT)
  - `src/routes/dumpSites.routes.ts` — CRUD for dump sites + cleanup reports, photo upload via multer
  - `src/auth.ts` — JWT middleware (requireAuth, optionalAuth)
  - `src/upload.ts` — multer config, uploads served from `/uploads`
  - `src/serialize.ts` — API response serializers
- **DB:** PostgreSQL 16 + PostGIS 3.4 via Docker (`docker-compose.yml`)
  - Note: PostGIS is set up in schema (geom column, spatial index, trigger) but **no queries currently use PostGIS functions** — all queries use plain lat/lng columns. Could run without PostGIS if needed.
- **Scripts:** `npm run dev` (tsx watch), `npm run build` (tsc), `npm start` (node dist/), `npm run migrate`, `npm run db:up` (docker compose)
- **Env:** See `.env.example` — needs DATABASE_URL, JWT_SECRET, PUBLIC_URL, CORS_ORIGINS

### 2. Mobile App (`/mobile`)
- **Stack:** Expo SDK 57 + React Native 0.86.2
- **Key dependencies:** expo-dev-client, react-native-maps, expo-camera, expo-location, expo-sqlite, expo-image-picker
- **Package name:** `com.forestwatch.app`
- **Key files:**
  - `App.tsx` — root, SafeAreaProvider + RootNavigator, DB init
  - `src/navigation/RootNavigator.tsx` — native-stack (auth) + bottom-tabs (Map, Capture, List) + SiteDetail
  - `src/screens/MapScreen.tsx` — map view of dump sites with markers
  - `src/screens/CaptureScreen.tsx` — camera capture + GPS + details form
  - `src/screens/ListScreen.tsx` — FlatList of dump sites with sync
  - `src/screens/DetailScreen.tsx` — site details + cleanup reports + status updates
  - `src/components/ui.tsx` — reusable components (Button, Chip, Badge, Field, PoweredByFooter)
  - `src/config.ts` — API_BASE_URL, SYNC_ENABLED, COLORS, DEFAULT_REGION
  - `src/types.ts` — TypeScript types (DumpSite, CleanupReport, etc.)
  - `src/db/` — local SQLite DB for offline storage + sync
- **Env:**
  - `.env` (emulator): `EXPO_PUBLIC_API_URL=http://localhost:4000`
  - `.env.production` (phone): `EXPO_PUBLIC_API_URL=http://192.168.0.111:4000`
- **Google Maps API key:** `AIzaSyA05rwJuORdp9Rvp4p0iNh2j0lHjuxK9es` (in app.json)
- **Keystore:** `mobile/android/app/forestwatch.keystore` (alias: forestwatch, password: Gnar1al!) — gitignored, needs manual copy
  - Debug SHA-1: `5E:8F:16:06:2E:A3:CD:2C:4A:0D:54:78:76:BA:A6:F3:8C:AB:F6:25`
  - Release SHA-1: `F9:62:C7:3A:69:A4:F5:C3:0D:A8:6B:CF:71:ED:49:46:33:D5:D1:82`
  - Both SHA-1s must be registered in Google Cloud Console API key restriction
- **Expo version note:** Always check https://docs.expo.dev/versions/v57.0.0/ before writing Expo code

### 3. Website (planned, not yet built)
- Will be hosted on Hostinger Premium Web Hosting
- Public-facing: map view of reported dump sites, volunteer login, cleanup reporting
- Will call backend API at a subdomain (e.g., `api.forestwatch.org`)

## Development Setup

### Prerequisites
- Node.js 20+, Git, Android Studio (for emulator), Docker (for local DB)
- Git Bash on Windows (all shell scripts use bash)
- JAVA_HOME must point to Android Studio's `jbr` directory (not `jre`)

### Local Development
1. Start DB: `cd backend && npm run db:up` (Docker PostGIS on port 5432)
2. Start backend: `cd backend && npm run dev` (port 4000)
3. Start mobile: `cd mobile && npx expo start --dev-client --android`
4. Or use the launch script: `bash launchForestWatch.sh` (from repo root, via Git Bash)

### Launch Script (`launchForestWatch.sh`)
Automates: Docker DB start, emulator launch, adb reverse port forwarding, mock GPS, backend start, Expo dev client launch.
- AVD name: `forestwatch` (Pixel 3a, Android 34)
- Mock GPS: Lake of the Woods Resort, OR (-122.212, 42.3785)

### Running on Physical Device (Samsung Note 8)
- Connect via USB, device ID: `ce10182ae1f84629047e`
- Set ANDROID_SERIAL env var to target the phone
- Use `--port 8082` for second Metro instance (emulator uses 8081)
- adb reverse: `adb -s <device> reverse tcp:4000 tcp:4000` and `adb -s <device> reverse tcp:8082 tcp:8082`
- Debug APK installed (release APK has different signature — must uninstall first)
- Launch: `npx expo start --dev-client --android --port 8082` with `ANDROID_SERIAL=ce10182ae1f84629047e`

## Current State

### Completed
- Backend API fully functional (auth, dump sites CRUD, cleanup reports, photo uploads)
- Mobile app: Map, Capture, List, Detail screens all working
- Offline SQLite storage + sync with backend
- "Powered by GnarTechs" footer on all screens (pinned to bottom, yellow #ffffcc text on rgba(0,0,0,0.45) background, "GnarTechs" in bold italic)
- Expo dev client builds for emulator and physical device (Note 8)

### In Progress
- Deployment planning: Hostinger VPS for backend+DB, Premium hosting for website
- Website frontend: not yet started

### Deployment Plan
- **Hostinger KVM1 VPS** — PostgreSQL/PostGIS (Docker) + Node.js backend (PM2) + Nginx reverse proxy + Let's Encrypt SSL
- **Hostinger Premium Web Hosting** (paid through 2029) — website frontend, domain management
- **Domain:** API on subdomain (e.g., `api.forestwatch.org`) → VPS IP; main domain → Premium hosting
- **Mobile app** — update `.env.production` to point to VPS API URL

## Key Decisions
- PostGIS kept in schema but not used in queries — can be dropped if migrating to MySQL
- Expo SDK 57 with expo-dev-client (not Expo Go, due to native modules)
- Release builds signed with forestwatch.keystore (gitignored)
- All shell scripts run via Git Bash on Windows

## Conventions
- Use Git Bash for all shell commands on Windows
- Minimal, focused edits — follow existing code style
- No comments/documentation unless explicitly requested
- PoweredByFooter component in `src/components/ui.tsx` — accept `style` prop for per-screen positioning

## Git
- Repo on GitHub
- User transitioned to a new laptop (keystore and .env files need manual copy)
