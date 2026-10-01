-- A1. Overall category demand ranking
SELECT
    Category,
    COUNT(*)          AS Total_Apps,
    AVG(Demand_Score) AS Avg_Demand_Score
FROM apps_with_demand_score
GROUP BY Category
ORDER BY Avg_Demand_Score DESC;

-- A2. Free vs Paid demand gap per category (core analysis)
SELECT
    f.Category,
    f.Avg_Demand_Score                    AS Free_Avg_Score,
    p.Avg_Demand_Score                    AS Paid_Avg_Score,
    p.Avg_Demand_Score - f.Avg_Demand_Score AS Score_Gap
FROM (
    SELECT
        Category,
        AVG(Demand_Score) AS Avg_Demand_Score
    FROM apps_with_demand_score
    WHERE Type = 'Free'
    GROUP BY Category
) AS f
JOIN (
    SELECT
        Category,
        AVG(Demand_Score) AS Avg_Demand_Score
    FROM apps_with_demand_score
    WHERE Type = 'Paid'
    GROUP BY Category
) AS p
    ON f.Category = p.Category
ORDER BY Score_Gap DESC;

-- A3. Categories with no Paid apps
--     Conversion cannot be recommended here: there is no comparison group
SELECT
    Category,
    COUNT(*) AS Total_Apps
FROM apps_with_demand_score
GROUP BY Category
HAVING SUM(CASE WHEN Type = 'Paid' THEN 1 ELSE 0 END) = 0;


-- B1. Paid app price range per category
--     Needed to suggest a price if conversion is recommended
SELECT
    Category,
    COUNT(*)   AS Paid_App_Count,
    AVG(Price) AS Avg_Price,
    MIN(Price) AS Min_Price,
    MAX(Price) AS Max_Price
FROM apps_with_demand_score
WHERE Type = 'Paid'
GROUP BY Category
ORDER BY Avg_Price DESC;


-- C1. Lowest-demand Free apps
SELECT TOP 20
    App,
    Category,
    Demand_Score,
    Installs,
    Rating
FROM apps_with_demand_score
WHERE Type = 'Free'
ORDER BY Demand_Score ASC;

-- C2. Highest-demand Paid apps, used as a benchmark (minimum 1,000 installs)
SELECT TOP 20
    App,
    Category,
    Demand_Score,
    Installs,
    Rating,
    Price
FROM apps_with_demand_score
WHERE Type = 'Paid'
  AND Installs >= 1000
ORDER BY Demand_Score DESC;


-- D1. Sentiment of the lowest-demand Free apps
--     Helps explain why their demand is low
SELECT TOP 20
    a.App,
    a.Category,
    a.Demand_Score,
    s.Positive_Pct,
    s.Total_Reviews
FROM apps_with_demand_score AS a
JOIN (
    SELECT
        App,
        COUNT(*) AS Total_Reviews,
        CAST(SUM(CASE WHEN Sentiment = 'Positive' THEN 1 ELSE 0 END) AS FLOAT)
            / COUNT(*) * 100 AS Positive_Pct
    FROM reviews_cleaned
    GROUP BY App
) AS s
    ON a.App = s.App
WHERE a.Type = 'Free'
ORDER BY a.Demand_Score ASC;