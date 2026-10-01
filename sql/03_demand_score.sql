-- 1.1 Min / max of the raw metrics
SELECT
    MIN(Installs) AS Min_Installs, MAX(Installs) AS Max_Installs,
    MIN(Rating)   AS Min_Rating,   MAX(Rating)   AS Max_Rating,
    MIN(Reviews)  AS Min_Reviews,  MAX(Reviews)  AS Max_Reviews
FROM apps_cleaned;

-- 1.2 Range of the engagement ratio (basis for the divisor of 4)
SELECT
    MIN(CAST(Reviews AS FLOAT) / NULLIF(Installs, 0)) AS Min_Engagement_Ratio,
    MAX(CAST(Reviews AS FLOAT) / NULLIF(Installs, 0)) AS Max_Engagement_Ratio
FROM apps_cleaned;
GO


DROP TABLE IF EXISTS apps_with_demand_score;
GO

CREATE TABLE apps_with_demand_score (
    App                    NVARCHAR(500),
    Category               NVARCHAR(50),
    Rating                 FLOAT,
    Reviews                INT,
    Installs               BIGINT,
    Type                   NVARCHAR(50),
    Price                  DECIMAL(10, 2),
    Engagement_Ratio       FLOAT,
    Normalized_Installs    FLOAT,
    Normalized_Rating      FLOAT,
    Normalized_Engagement  FLOAT,
    Demand_Score           FLOAT
);
GO

WITH category_avg_rating AS (
    SELECT
        Category,
        AVG(Rating) AS Avg_Rating
    FROM apps_cleaned
    WHERE Rating IS NOT NULL
    GROUP BY Category
),
base AS (
    SELECT
        a.App,
        a.Category,
        a.Rating,
        a.Reviews,
        a.Installs,
        a.Type,
        a.Price,
        CAST(a.Reviews AS FLOAT) / NULLIF(a.Installs, 0) AS Engagement_Ratio,
        COALESCE(a.Rating, c.Avg_Rating, 0)              AS Rating_Filled
    FROM apps_cleaned AS a
    LEFT JOIN category_avg_rating AS c
        ON a.Category = c.Category
)
INSERT INTO apps_with_demand_score (
    App, Category, Rating, Reviews, Installs, Type, Price,
    Engagement_Ratio, Normalized_Installs, Normalized_Rating,
    Normalized_Engagement, Demand_Score
)
SELECT
    App,
    Category,
    Rating,
    Reviews,
    Installs,
    Type,
    Price,
    Engagement_Ratio,
    CAST(Installs AS FLOAT) / 1000000000                AS Normalized_Installs,
    (Rating_Filled - 1) / (5 - 1)                       AS Normalized_Rating,
    Engagement_Ratio / 4                                AS Normalized_Engagement,
    (0.45 * (CAST(Installs AS FLOAT) / 1000000000))
    + (0.35 * ((Rating_Filled - 1) / (5 - 1)))
    + (0.20 * (ISNULL(Engagement_Ratio, 0) / 4))        AS Demand_Score
FROM base;
GO

-- 3.1 Category average ratings used to fill missing ratings
SELECT
    Category,
    AVG(Rating) AS Avg_Category_Rating
FROM apps_with_demand_score
WHERE Rating IS NOT NULL
GROUP BY Category
ORDER BY Category;

-- 3.2 Apps whose rating was originally missing: confirm they were filled
SELECT TOP 10
    App,
    Category,
    Rating,
    Normalized_Rating,
    Demand_Score
FROM apps_with_demand_score
WHERE Rating IS NULL;

-- 3.3 Top 10 apps by Demand_Score: sanity check the ranking
SELECT TOP 10
    App,
    Category,
    Demand_Score,
    Installs,
    Rating,
    Reviews,
    Engagement_Ratio
FROM apps_with_demand_score
ORDER BY Demand_Score DESC;
GO