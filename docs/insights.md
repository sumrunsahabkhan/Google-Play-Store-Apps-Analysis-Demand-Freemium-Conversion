# Insights & Final Recommendation

## Business Question

Should the company convert its low-demand free apps into a paid or freemium model to increase revenue, and which app categories are the safest candidates?

## Answer: Conditional Yes, for 4 Categories

Based on Demand Score and sentiment analysis across 9,636 apps, freemium conversion is recommended only for select categories, not as a blanket strategy.

## Scope

- **Data:** Google Play Store Apps (~10,000 apps) and User Reviews (~64,000 reviews), scraped in 2018.
- **Focus:** Free vs Paid apps across all categories.
- **Demand Score:** 45% Installs, 35% Rating, 20% Engagement Ratio (Reviews / Installs), each normalized.
- **Score Gap:** average Demand Score of Paid apps minus that of Free apps, per category.

## Recommended Categories (Safe to Convert)

| Category | Score Gap (Paid - Free) | Low-Demand Free Apps | Est. Revenue (10% retention) | Status |
|---|---|---|---|---|
| News & Magazines | +0.057 (highest) | 146 | $22.4M | Safe |
| Art & Design | +0.040 | 22 | $1.5M | Safe |
| Education | +0.039 | 35 | $9.5M | Safe |
| Entertainment | +0.038 | TBD | TBD | Safe (added after dashboard review) |

**Reasoning:** In these categories, existing Paid apps consistently outperform Free apps in Demand Score, suggesting users here associate payment with quality and trust rather than being deterred by it.

**Note on Entertainment:** This category was not specifically checked in the Phase 5 SQL analysis. Its Score Gap (about +0.038) was discovered and confirmed while building the Power BI table, and is comparable to Education. Its low-demand app count and revenue estimate still need to be filled in.

## Categories to Avoid (Do Not Convert)

| Category | Score Gap | Why |
|---|---|---|
| Parenting | -0.077 | Free apps significantly outperform paid |
| Social | -0.044 | Free apps dominate (network effects likely) |
| Finance | -0.022 | Free apps perform better despite a high average paid price (~$140) |

**Reasoning:** In these categories Free apps have higher demand than Paid, so converting would likely hurt installs without proof that users will pay.

## Special Case: Medical

The Score Gap is nearly flat (+0.0006), suggesting price isn't the driver of demand. Sentiment analysis showed several Medical apps with positive review rates below 30% (e.g., Anthem BC Anywhere at 25.8%).

**Recommendation:** Fix usability and trust issues first. A pricing model change alone won't solve low demand here.

## Categories Excluded (No Comparison Possible)

Beauty, Comics, and House_and_Home had no paid apps at all, so no Score Gap could be calculated. They are excluded from the recommendation.

## Revenue Potential

| Retention | News & Magazines | Art & Design | Education | Total (3 categories) |
|---|---|---|---|---|
| 5% | $11.2M | $0.75M | $4.75M | ~$16.7M |
| 10% | $22.4M | $1.5M | $9.5M | ~$33.4M |
| 15% | $33.6M | $2.25M | $14.25M | ~$50.1M |

- The 5% and 15% rows scale the 10% figures linearly. Check them against the output of `05_revenue_estimate.sql`.
- Entertainment is not included until its estimate is computed.
- News & Magazines offers the largest opportunity.

## How the Estimates Work

- Retention is the assumed share of a converted app's existing installs that stay after it becomes paid.
- Price is assumed to equal the category's current average paid price.
- Retention rates (5% to 15%) are assumptions, not observed data.

## Assumptions

- Weights (45/35/20) and scaling limits are analyst choices, not industry standards.
- "Low demand" means a Demand Score below the overall average.
- Missing ratings are filled with the category average (not zero).
- Sentiment uses only reviews already translated to English.

## Limitations

- **Correlational, not causal:** apps that are already paid may simply attract higher-quality developers; this doesn't prove that converting a free app will replicate that success.
- **Dated data:** 2018 snapshot, Google Play only; market conditions may have changed.
- **Estimates only:** revenue figures are directional, not forecasts, and ignore lost ad revenue and user drop-off.
- **Installs are ranges** (e.g., 10,000+), and a few very large apps skew the installs component.
- **Partial review coverage:** reviews exist for only ~1,074 unique apps.
- **Small samples:** e.g., only 2 paid apps in News & Magazines for price benchmarking.
- **Untested reverse strategy:** Paid to Free for underperforming paid apps could be a valuable follow-up.