-- 1. Revenue scenarios: 5%, 10% and 15% of installs convert
-- Low demand = Demand_Score below the overall average.
-- Revenue = total installs x conversion rate x category average paid price.

SELECT
    a.Category,
    COUNT(*)                                        AS Low_Demand_App_Count,
    SUM(a.Installs)                                 AS Total_Installs,
    p.Avg_Paid_Price,
    SUM(a.Installs) * 0.05 * p.Avg_Paid_Price       AS Revenue_At_5Pct,
    SUM(a.Installs) * 0.10 * p.Avg_Paid_Price       AS Revenue_At_10Pct,
    SUM(a.Installs) * 0.15 * p.Avg_Paid_Price       AS Revenue_At_15Pct
FROM apps_with_demand_score AS a
JOIN (
    SELECT
        Category,
        AVG(Price) AS Avg_Paid_Price
    FROM apps_with_demand_score
    WHERE Type = 'Paid'
    GROUP BY Category
) AS p
    ON a.Category = p.Category
WHERE a.Type = 'Free'
  AND a.Category IN ('NEWS_AND_MAGAZINES', 'ART_AND_DESIGN', 'EDUCATION')
  AND a.Demand_Score < (SELECT AVG(Demand_Score) FROM apps_with_demand_score)
GROUP BY
    a.Category,
    p.Avg_Paid_Price
ORDER BY Revenue_At_10Pct DESC;
GO

-- 2. Table update: add Content_Rating from apps_cleaned

ALTER TABLE apps_with_demand_score
ADD Content_Rating NVARCHAR(50);
GO

UPDATE a
SET a.Content_Rating = c.Content_Rating
FROM apps_with_demand_score AS a
JOIN apps_cleaned AS c
    ON a.App = c.App;
GO