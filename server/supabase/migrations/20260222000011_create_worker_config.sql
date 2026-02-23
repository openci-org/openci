-- worker_config: key-value store for Mac worker configuration
-- Replaces Firestore worker_config_v0 collection

CREATE TABLE public.worker_config (
  key        text        PRIMARY KEY,
  value      text        NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Seed the initial version entry
INSERT INTO public.worker_config (key, value)
VALUES ('latest_version', '0.0.1')
ON CONFLICT (key) DO NOTHING;
