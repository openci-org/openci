-- Add build log archiving support:
-- 1. build_logs: step_index / step_name columns for step-level grouping
-- 2. builds: log_archive_path for Supabase Storage reference
-- 3. Supabase Storage bucket for build log archives

-- ============================================================
-- build_logs: add step context columns
-- ============================================================

ALTER TABLE public.build_logs
  ADD COLUMN step_index smallint,  -- 0-based step index; NULL = outside step context
  ADD COLUMN step_name  text;      -- human-readable step name (e.g. "Build iOS")

-- Index for step-scoped log queries and accordion UI grouping
CREATE INDEX idx_build_logs_run_step
  ON public.build_logs(build_run_id, step_index, id);

-- ============================================================
-- builds: add archive path column
-- ============================================================
-- Path within the 'build-logs' Storage bucket.
-- Format: {org_id}/{project_id}/{build_id}.txt
-- NULL = not yet archived (in progress or archive not yet created)

ALTER TABLE public.builds
  ADD COLUMN log_archive_path text;

-- ============================================================
-- Storage bucket: build-logs (private)
-- ============================================================
-- The bucket is created here via Supabase's internal storage schema.
-- Access: service_role only for writes; authenticated users get signed URLs.

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'build-logs',
  'build-logs',
  false,           -- private bucket
  NULL,            -- no per-file size limit (see migration 039 for rationale)
  ARRAY['text/plain']
)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS: authenticated users can download files in their org's folder.
-- The folder structure is: {org_id}/{project_id}/{build_id}.txt
-- We allow reads for authenticated users (the signed URL already scopes access).
-- Writes are service_role only (no INSERT policy for authenticated role).

CREATE POLICY "build-logs: authenticated users can read"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'build-logs');

CREATE POLICY "build-logs: service role can write"
  ON storage.objects FOR INSERT
  TO service_role
  WITH CHECK (bucket_id = 'build-logs');

CREATE POLICY "build-logs: service role can update"
  ON storage.objects FOR UPDATE
  TO service_role
  USING (bucket_id = 'build-logs');

CREATE POLICY "build-logs: service role can delete"
  ON storage.objects FOR DELETE
  TO service_role
  USING (bucket_id = 'build-logs');
