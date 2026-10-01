-- 1.1 Rows with an impossible rating (> 5);
SELECT *
FROM apps_raw
WHERE TRY_CAST(Rating AS FLOAT) > 5;

-- 1.2 Duplicate app names; 
SELECT
    App,
    COUNT(*) AS duplicate_count
FROM apps_raw
GROUP BY App
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- 1.3 Baseline row count
SELECT COUNT(*) AS apps_raw_rows
FROM apps_raw;
GO


DROP TABLE IF EXISTS apps_cleaned;
GO

CREATE TABLE apps_cleaned (
    App             NVARCHAR(500),
    Category        NVARCHAR(50),
    Rating          FLOAT NULL,
    Reviews         INT,
    Size_MB         FLOAT NULL,
    Installs        BIGINT,
    Type            NVARCHAR(50),
    Price           DECIMAL(10, 2),
    Content_Rating  NVARCHAR(50),
    Genres          NVARCHAR(500),
    Last_Updated    NVARCHAR(50),
    Current_Ver     NVARCHAR(50),
    Android_Ver     NVARCHAR(50)
);
GO


WITH ranked_apps AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY App
            ORDER BY TRY_CAST(Reviews AS INT) DESC
        ) AS rn
    FROM apps_raw
    WHERE Type IN ('Free', 'Paid')
      AND (
            TRY_CAST(Rating AS FLOAT) IS NULL
            OR TRY_CAST(Rating AS FLOAT) BETWEEN 0 AND 5
          )
)
INSERT INTO apps_cleaned (
    App, Category, Rating, Reviews, Size_MB, Installs, Type, Price,
    Content_Rating, Genres, Last_Updated, Current_Ver, Android_Ver
)
SELECT
    App,
    Category,
    TRY_CAST(Rating AS FLOAT)                                   AS Rating,
    TRY_CAST(Reviews AS INT)                                    AS Reviews,
    CASE
        WHEN Size = 'Varies with device' THEN NULL
        WHEN Size LIKE '%M' THEN TRY_CAST(REPLACE(Size, 'M', '') AS FLOAT)
        WHEN Size LIKE '%k' THEN TRY_CAST(REPLACE(Size, 'k', '') AS FLOAT) / 1024
        ELSE NULL
    END                                                         AS Size_MB,
    TRY_CAST(REPLACE(REPLACE(Installs, ',', ''), '+', '') AS BIGINT) AS Installs,
    Type,
    TRY_CAST(REPLACE(Price, '$', '') AS DECIMAL(10, 2))         AS Price,
    Content_Rating,
    Genres,
    Last_Updated,
    Current_Ver,
    Android_Ver
FROM ranked_apps
WHERE rn = 1;
GO



/* ---------------------------------------------------------------------
   3. Build reviews_cleaned
   --------------------------------------------------------------------- */

DROP TABLE IF EXISTS reviews_cleaned;
GO

CREATE TABLE reviews_cleaned (
    App                     NVARCHAR(500),
    Translated_Review       NVARCHAR(MAX),
    Sentiment               NVARCHAR(50),
    Sentiment_Polarity      FLOAT,
    Sentiment_Subjectivity  FLOAT
);
GO

INSERT INTO reviews_cleaned (
    App, Translated_Review, Sentiment, Sentiment_Polarity, Sentiment_Subjectivity
)
SELECT
    App,
    Translated_Review,
    Sentiment,
    TRY_CAST(Sentiment_Polarity AS FLOAT)       AS Sentiment_Polarity,
    TRY_CAST(Sentiment_Subjectivity AS FLOAT)   AS Sentiment_Subjectivity
FROM reviews_raw
WHERE Sentiment IS NOT NULL
  AND Sentiment <> 'nan'
  AND Translated_Review IS NOT NULL
  AND Translated_Review <> 'nan';
GO


/* ---------------------------------------------------------------------
   4. Validation checks
   --------------------------------------------------------------------- */

-- 4.1 Row counts after cleaning
SELECT COUNT(*) AS apps_cleaned_rows
FROM apps_cleaned;

SELECT COUNT(*) AS reviews_cleaned_rows
FROM reviews_cleaned;

-- 4.2 NULL counts for the key numeric columns
SELECT
    SUM(CASE WHEN Installs IS NULL THEN 1 ELSE 0 END) AS null_installs,
    SUM(CASE WHEN Price    IS NULL THEN 1 ELSE 0 END) AS null_price,
    SUM(CASE WHEN Rating   IS NULL THEN 1 ELSE 0 END) AS null_rating
FROM apps_cleaned;

-- 4.3 Range checks (expected: 0 rows each)
SELECT *
FROM apps_cleaned
WHERE Rating < 0 OR Rating > 5;

SELECT *
FROM apps_cleaned
WHERE Installs < 0 OR Reviews < 0;

SELECT *
FROM apps_cleaned
WHERE Price < 0;

-- 4.4 Consistency: Free apps must have Price = 0 (expected: 0 rows)
SELECT *
FROM apps_cleaned
WHERE Type = 'Free' AND Price > 0;

-- 4.5 Categorical values: only 'Free' and 'Paid' should appear in Type
SELECT DISTINCT Type
FROM apps_cleaned;

-- 4.6 Category list: look for unexpected or malformed values
SELECT DISTINCT Category
FROM apps_cleaned
ORDER BY Category;

-- 4.7 Orphan reviews: reviews whose App does not exist in apps_cleaned
SELECT COUNT(*) AS orphan_review_rows
FROM reviews_cleaned AS r
WHERE NOT EXISTS (
    SELECT 1
    FROM apps_cleaned AS a
    WHERE a.App = r.App
);


SELECT DISTINCT TOP 10
    r.App
FROM reviews_cleaned AS r
WHERE NOT EXISTS (
    SELECT 1
    FROM apps_cleaned AS a
    WHERE a.App = r.App
);

-- 4.8 Leading/trailing whitespace (expected: 0 for both)
SELECT
    SUM(CASE WHEN App      <> TRIM(App)      THEN 1 ELSE 0 END) AS app_whitespace_rows,
    SUM(CASE WHEN Category <> TRIM(Category) THEN 1 ELSE 0 END) AS category_whitespace_rows
FROM apps_cleaned;

-- 4.9 Known limitation: Last_Updated is stored as text (e.g. 'January 7, 2018').
SELECT TOP 5
    Last_Updated
FROM apps_cleaned;
GO