-- Funnel Analysis Query
-- This query computes the number of users who reach each step of the product funnel
-- from first app open through first investment. It summarises the unique users at
-- each step and can be used to calculate conversion and drop-off rates.

WITH step_flags AS (
    SELECT
        user_id,
        /* Mark whether the user performed each funnel event */
        MAX(CASE WHEN event_name = 'app_open' THEN 1 ELSE 0 END)    AS app_open,
        MAX(CASE WHEN event_name = 'complete_signup' THEN 1 ELSE 0 END) AS signup_completed,
        MAX(CASE WHEN event_name = 'link_bank' THEN 1 ELSE 0 END)    AS bank_linked,
        MAX(CASE WHEN event_name = 'fund_account' THEN 1 ELSE 0 END) AS account_funded,
        MAX(CASE WHEN event_name = 'make_investment' THEN 1 ELSE 0 END) AS first_investment
    FROM events
    GROUP BY user_id
),
counts AS (
    SELECT
        COUNT(DISTINCT CASE WHEN app_open = 1 THEN user_id END)        AS app_open_users,
        COUNT(DISTINCT CASE WHEN signup_completed = 1 THEN user_id END)   AS signup_completed_users,
        COUNT(DISTINCT CASE WHEN bank_linked = 1 THEN user_id END)     AS bank_linked_users,
        COUNT(DISTINCT CASE WHEN account_funded = 1 THEN user_id END)   AS account_funded_users,
        COUNT(DISTINCT CASE WHEN first_investment = 1 THEN user_id END) AS first_investment_users
    FROM step_flags
)
SELECT *
FROM counts;
