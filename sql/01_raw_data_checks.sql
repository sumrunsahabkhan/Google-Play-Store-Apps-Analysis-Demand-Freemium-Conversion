-- 1. Row counts
SELECT COUNT(*) AS apps_raw_rows
FROM apps_raw;

SELECT COUNT(*) AS reviews_raw_rows
FROM reviews_raw;

-- 2. Sample rows
SELECT TOP 5 *
FROM apps_raw;

SELECT TOP 5 *
FROM reviews_raw;