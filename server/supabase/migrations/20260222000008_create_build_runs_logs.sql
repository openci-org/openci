-- build_runs: each attempt to execute a build (supports retries)

CREATE TABLE public.build_runs (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  build_id    uuid        NOT NULL REFERENCES public.builds(id) ON DELETE CASCADE,
  -- 'in_progress' | 'completed'
  status      text        NOT NULL DEFAULT 'in_progress'
    CHECK (status IN ('in_progress', 'completed')),
  -- 'success' | 'failure' | 'cancelled' (NULL while in_progress)
  conclusion  text
    CHECK (conclusion IN ('success', 'failure', 'cancelled')),
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_build_runs_build_id ON public.build_runs(build_id);

-- Auto-update builds.latest_run_id and run_count when a new run starts
CREATE OR REPLACE FUNCTION public.update_build_on_run_created()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
BEGIN
  UPDATE public.builds
  SET
    latest_run_id = NEW.id,
    run_count     = run_count + 1,
    updated_at    = now()
  WHERE id = NEW.build_id;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_build_run_created
  AFTER INSERT ON public.build_runs
  FOR EACH ROW EXECUTE FUNCTION public.update_build_on_run_created();

CREATE TRIGGER build_runs_updated_at
  BEFORE UPDATE ON public.build_runs
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- build_logs: real-time streaming logs written by the Mac worker
-- Immutable: no updated_at, no UPDATE policy

CREATE TABLE public.build_logs (
  id           bigserial   PRIMARY KEY,  -- bigserial for time-ordered streaming
  build_run_id uuid        NOT NULL REFERENCES public.build_runs(id) ON DELETE CASCADE,
  -- Denormalized for efficient RLS check without JOIN
  build_id     uuid        NOT NULL REFERENCES public.builds(id) ON DELETE CASCADE,
  message      text        NOT NULL,
  level        log_level   NOT NULL DEFAULT 'info',
  stack_trace  text,
  created_at   timestamptz NOT NULL DEFAULT now()
);

-- Primary query: all logs for a run, in insertion order
CREATE INDEX idx_build_logs_run_id_created
  ON public.build_logs(build_run_id, created_at ASC);

-- RLS policy and Realtime subscription filter
CREATE INDEX idx_build_logs_build_id ON public.build_logs(build_id);

-- Enable Realtime for live log streaming in the dashboard
ALTER PUBLICATION supabase_realtime ADD TABLE public.builds;
ALTER PUBLICATION supabase_realtime ADD TABLE public.build_logs;
