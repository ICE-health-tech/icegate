-- Track originating device local path + canonical S3 key for photo stories.
ALTER TABLE public.achievement_story_sync
  ADD COLUMN IF NOT EXISTS local_path text,
  ADD COLUMN IF NOT EXISTS device text,
  ADD COLUMN IF NOT EXISTS remote_path text;

ALTER TABLE public.achievement_story_sync
  DROP CONSTRAINT IF EXISTS achievement_story_sync_device_check;

ALTER TABLE public.achievement_story_sync
  ADD CONSTRAINT achievement_story_sync_device_check
  CHECK (device IS NULL OR device IN ('ios', 'mac', 'android', 'other'));

UPDATE public.achievement_story_sync
SET remote_path = image_s3_path
WHERE remote_path IS NULL
  AND image_s3_path IS NOT NULL;

COMMENT ON COLUMN public.achievement_story_sync.local_path IS
  'App-documents relative path on the device that uploaded the image';
COMMENT ON COLUMN public.achievement_story_sync.remote_path IS
  'Canonical S3 object key shared across ios/mac';
COMMENT ON COLUMN public.achievement_story_sync.device IS
  'Originating device: ios | mac | android | other';
