-- Increase the build-logs Storage bucket file size limit.
-- 10 MB was too small for large builds (e.g. Xcode). NULL = no limit (capped by
-- Supabase plan quota, not per-file).
UPDATE storage.buckets
SET file_size_limit = NULL
WHERE id = 'build-logs';
