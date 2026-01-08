-- Cohort & Retention Analysis Query
-- This query cohorts users by the week of their signup (starting on Monday) and
-- counts how many unique users are active in each subsequent week. Activity is
-- defined as any of the key engagement events: app_open, view_portfolio or
-- make_investment. The week_index column starts at 0 for the signup week,
-- 1 for the first week after signup, and so on. Use this result set to
-- calculate retention rates by dividing the active_users by the cohort size.

WITH cohort_assignment AS (
    SELECT
        u.user_id,
        -- Align signup date to Monday (start of week)
        date_trunc('week', u.signup_date) AS cohort_week,
        u.signup_date
    FROM users u
),
event_activity AS (
    SELECT
        e.user_id,
        c.cohort_week,
        /* Compute number of whole weeks between signup and event */
        FLOOR(EXTRACT(epoch FROM (e.event_time - c.signup_date)) / (7 * 24 * 60 * 60))::INT AS week_index
    FROM events e
    JOIN cohort_assignment c
      ON e.user_id = c.user_id
    WHERE e.event_name IN ('app_open', 'view_portfolio', 'make_investment')
      AND e.event_time >= c.signup_date
)
SELECT
    cohort_week,
    week_index,
    COUNT(DISTINCT user_id) AS active_users
FROM event_activity
GROUP BY cohort_week, week_index
ORDER BY cohort_week, week_index;
