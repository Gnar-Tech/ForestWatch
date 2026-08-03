-- ForestWatch schema (Postgres + PostGIS)
-- Idempotent: safe to run repeatedly.

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto; -- for gen_random_uuid()

-- Volunteers who log in to the website to report cleanup activity.
CREATE TABLE IF NOT EXISTS volunteers (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email        TEXT UNIQUE NOT NULL,
  name         TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Dump sites reported from the mobile app (may be anonymous).
CREATE TABLE IF NOT EXISTS dump_sites (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id     TEXT,                       -- id generated on device (idempotency)
  title         TEXT NOT NULL,
  description   TEXT NOT NULL DEFAULT '',
  category      TEXT NOT NULL DEFAULT 'litter',
  severity      TEXT NOT NULL DEFAULT 'medium',
  status        TEXT NOT NULL DEFAULT 'reported',
  latitude      DOUBLE PRECISION NOT NULL,
  longitude     DOUBLE PRECISION NOT NULL,
  accuracy      DOUBLE PRECISION,
  altitude      DOUBLE PRECISION,
  geom          geography(Point, 4326),
  photo_path    TEXT,
  reporter_name TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_dump_sites_client_id
  ON dump_sites (client_id) WHERE client_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_dump_sites_geom ON dump_sites USING GIST (geom);
CREATE INDEX IF NOT EXISTS idx_dump_sites_status ON dump_sites (status);

-- Cleanup follow-ups tied to a dump site, submitted by volunteers.
CREATE TABLE IF NOT EXISTS cleanup_reports (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id      TEXT,
  dump_site_id   UUID NOT NULL REFERENCES dump_sites(id) ON DELETE CASCADE,
  volunteer_id   UUID REFERENCES volunteers(id) ON DELETE SET NULL,
  volunteer_name TEXT NOT NULL DEFAULT '',
  notes          TEXT NOT NULL DEFAULT '',
  photo_path     TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_cleanup_client_id
  ON cleanup_reports (client_id) WHERE client_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_cleanup_site ON cleanup_reports (dump_site_id);

-- Keep geom + updated_at in sync with lat/lng on write.
CREATE OR REPLACE FUNCTION dump_sites_sync_geom() RETURNS trigger AS $$
BEGIN
  NEW.geom := ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography;
  NEW.updated_at := now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_dump_sites_geom ON dump_sites;
CREATE TRIGGER trg_dump_sites_geom
  BEFORE INSERT OR UPDATE OF latitude, longitude ON dump_sites
  FOR EACH ROW EXECUTE FUNCTION dump_sites_sync_geom();
