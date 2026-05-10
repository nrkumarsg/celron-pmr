-- ============================================================
-- CelRon Preventive Maintenance - Supabase Schema Migration
-- Run this in: Supabase Dashboard > SQL Editor > New Query
-- Project: dfoihdzpgkrtyerzzchm
-- ============================================================

-- 1. SITES table
CREATE TABLE IF NOT EXISTS public.sites (
  id                  TEXT PRIMARY KEY,
  company_id          TEXT NOT NULL DEFAULT 'celron',
  name                TEXT NOT NULL,
  partner_name        TEXT NOT NULL DEFAULT '',
  partner_hq_address  TEXT NOT NULL DEFAULT '',
  address             TEXT NOT NULL DEFAULT ''
);

-- Enable Row Level Security (RLS) but allow all for anon key
ALTER TABLE public.sites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all operations on sites" ON public.sites
  FOR ALL USING (true) WITH CHECK (true);

-- Enable real-time for sites (required for .stream() in Flutter)
ALTER PUBLICATION supabase_realtime ADD TABLE public.sites;


-- 2. ASSETS table
CREATE TABLE IF NOT EXISTS public.assets (
  id          TEXT PRIMARY KEY,
  site_id     TEXT NOT NULL REFERENCES public.sites(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  reference   TEXT NOT NULL DEFAULT '',
  model       TEXT NOT NULL DEFAULT '',
  type        TEXT NOT NULL DEFAULT '',
  location    TEXT NOT NULL DEFAULT '',
  rpm         DOUBLE PRECISION NOT NULL DEFAULT 0.0,
  hz          DOUBLE PRECISION NOT NULL DEFAULT 0.0,
  power_kw    DOUBLE PRECISION NOT NULL DEFAULT 0.0
);

ALTER TABLE public.assets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all operations on assets" ON public.assets
  FOR ALL USING (true) WITH CHECK (true);

ALTER PUBLICATION supabase_realtime ADD TABLE public.assets;


-- 3. INSPECTIONS table
CREATE TABLE IF NOT EXISTS public.inspections (
  id                TEXT PRIMARY KEY,
  asset_id          TEXT NOT NULL REFERENCES public.assets(id) ON DELETE CASCADE,
  date              TIMESTAMPTZ NOT NULL DEFAULT now(),
  project_ref       TEXT NOT NULL DEFAULT '',
  partner_ref       TEXT NOT NULL DEFAULT '',
  inspection_by     TEXT NOT NULL DEFAULT '',
  quarterly_cycle   TEXT NOT NULL DEFAULT '',
  vibration_g       DOUBLE PRECISION NOT NULL DEFAULT 0.0,
  temperature_c     DOUBLE PRECISION NOT NULL DEFAULT 0.0,
  vibration_img_url TEXT,
  temp_img_url      TEXT,
  motor_parameters  JSONB NOT NULL DEFAULT '{}',
  pump_parameters   JSONB NOT NULL DEFAULT '{}',
  pipe_parameters   JSONB NOT NULL DEFAULT '{}',
  other_parameters  JSONB NOT NULL DEFAULT '{}',
  overall_status    TEXT NOT NULL DEFAULT 'NORMAL'
);

ALTER TABLE public.inspections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all operations on inspections" ON public.inspections
  FOR ALL USING (true) WITH CHECK (true);

ALTER PUBLICATION supabase_realtime ADD TABLE public.inspections;


-- 4. SERVICE_VISITS table (Maintenance Jobs)
CREATE TABLE IF NOT EXISTS public.service_visits (
  id            TEXT PRIMARY KEY,
  site_id       TEXT NOT NULL REFERENCES public.sites(id) ON DELETE CASCADE,
  celron_ref    TEXT NOT NULL DEFAULT '',
  customer_ref  TEXT NOT NULL DEFAULT '',
  visit_date    TIMESTAMPTZ NOT NULL DEFAULT now(),
  notes         TEXT NOT NULL DEFAULT '',
  status        TEXT NOT NULL DEFAULT 'OPEN',
  job_type      TEXT NOT NULL DEFAULT 'AD_HOC',
  contract_ends TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.service_visits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all operations on service_visits" ON public.service_visits
  FOR ALL USING (true) WITH CHECK (true);

ALTER PUBLICATION supabase_realtime ADD TABLE public.service_visits;

-- 5. Extend inspections with visit_id
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='inspections' AND column_name='visit_id') THEN
        ALTER TABLE public.inspections ADD COLUMN visit_id TEXT REFERENCES public.service_visits(id) ON DELETE SET NULL;
    END IF;
END $$;


-- ============================================================
-- VERIFY: Run this SELECT to confirm all tables were created
-- ============================================================
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('sites', 'assets', 'inspections', 'service_visits')
ORDER BY table_name;
