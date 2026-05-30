-- Deduplicate skills rows and prevent future duplicates (person + category + name).

UPDATE public.skills
SET skill_category = 'person:library'
WHERE skill_category = 'mind:boost';

WITH ranked AS (
  SELECT
    id,
    ROW_NUMBER() OVER (
      PARTITION BY
        person_id,
        lower(trim(skill_name)),
        coalesce(skill_category, '')
      ORDER BY
        years_of_experience DESC NULLS LAST,
        updated_at DESC NULLS LAST,
        id
    ) AS rn
  FROM public.skills
  WHERE person_id IS NOT NULL
    AND trim(skill_name) <> ''
)
DELETE FROM public.skills s
USING ranked r
WHERE s.id = r.id
  AND r.rn > 1;

CREATE UNIQUE INDEX IF NOT EXISTS skills_person_name_category_uidx
  ON public.skills (
    person_id,
    lower(trim(skill_name)),
    coalesce(skill_category, '')
  );

COMMENT ON INDEX public.skills_person_name_category_uidx IS
  'One skill row per person, name, and category (incl. project:<id>).';
