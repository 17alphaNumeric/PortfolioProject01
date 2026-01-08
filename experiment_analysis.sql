-- Experiment Evaluation Query
-- This query evaluates the onboarding redesign experiment by computing the
-- funded account conversion rate for each variant (control vs treatment).
-- It also calculates the average time (in days) from signup to first
-- investment for users who invest, and retains metrics needed for
-- short-term retention analysis (7‑day and 30‑day).

-- Conversion metrics
WITH conversion_counts AS (
    SELECT
        ex.variant,
        COUNT(DISTINCT ex.user_id) AS total_users,
        COUNT(DISTINCT CASE WHEN ev.event_name = 'fund_account' THEN ev.user_id END) AS funded_users
    FROM experiments ex
    LEFT JOIN events ev
      ON ex.user_id = ev.user_id
    GROUP BY ex.variant
),
conversion_rates AS (
    SELECT
        variant,
        total_users,
        funded_users,
        funded_users::DECIMAL / NULLIF(total_users, 0) AS conversion_rate
    FROM conversion_counts
),
-- Time to first investment
first_investment AS (
    SELECT
        ex.variant,
        e.user_id,
        MIN(e.event_time) AS first_invest_time
    FROM events e
    JOIN experiments ex ON ex.user_id = e.user_id
    WHERE e.event_name = 'make_investment'
    GROUP BY ex.variant, e.user_id
),
signup_dates AS (
    SELECT user_id, signup_date FROM users
),
time_to_invest AS (
    SELECT
        fi.variant,
        fi.user_id,
        EXTRACT(day FROM (fi.first_invest_time - sd.signup_date)) AS days_to_invest
    FROM first_investment fi
    JOIN signup_dates sd ON sd.user_id = fi.user_id
)
SELECT
    cr.variant,
    cr.total_users,
    cr.funded_users,
    cr.conversion_rate,
    AVG(ti.days_to_invest) AS avg_days_to_invest,
    MEDIAN(ti.days_to_invest) AS median_days_to_invest
FROM conversion_rates cr
LEFT JOIN time_to_invest ti ON ti.variant = cr.variant
GROUP BY cr.variant, cr.total_users, cr.funded_users, cr.conversion_rate
ORDER BY cr.variant;
