-- Track journal note image paths for ios/mac cross-device sync.
ALTER TABLE public.project_notes
  ADD COLUMN IF NOT EXISTS local_path text,
  ADD COLUMN IF NOT EXISTS device text,
  ADD COLUMN IF NOT EXISTS remote_path text;

ALTER TABLE public.project_notes
  DROP CONSTRAINT IF EXISTS project_notes_device_check;

ALTER TABLE public.project_notes
  ADD CONSTRAINT project_notes_device_check
  CHECK (device IS NULL OR device IN ('ios', 'mac', 'android', 'other'));

COMMENT ON COLUMN public.project_notes.local_path IS
  'App-documents relative path on the device that uploaded the image';
COMMENT ON COLUMN public.project_notes.remote_path IS
  'Canonical S3 object key shared across ios/mac';
COMMENT ON COLUMN public.project_notes.device IS
  'Originating device: ios | mac | android | other';
