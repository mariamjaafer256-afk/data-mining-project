-- OPTIONAL FIX. Read docs/KNOWN_ISSUES.md first and BACKUP the database before running anything below.
-- Problem: gold.dim_user had 32,486 rows (= silver.ldap snapshots) instead of 1000 users, so joining facts to it
-- repeats every event once per snapshot: gold.fact_activity has 42,147,175 rows vs 1,264,397 in silver.activity.
USE InsiderThreat;
GO
-- ---------- STEP 1: diagnose (run these first, nothing is changed) ----------
-- 1a. users repeated in gold.dim_user (expect many rows if the diagnosis is right)
SELECT TOP 5 user_id, COUNT(*) AS copies FROM gold.dim_user GROUP BY user_id ORDER BY copies DESC;
-- 1b. distinct events in the fact vs rows (rows >> distinct means duplicated events)
SELECT COUNT_BIG(*) AS fact_rows, COUNT_BIG(DISTINCT activity_key) AS distinct_activity_keys FROM gold.fact_activity;
-- 1c. event types and user key format in silver.activity
SELECT event_type, COUNT_BIG(*) AS n FROM silver.activity GROUP BY event_type;
SELECT TOP 5 [user], pc FROM silver.activity;
SELECT TOP 5 user_id FROM silver.dim_user;
GO
-- ---------- STEP 2: rebuild (uncomment after checking step 1) ----------
/*
BEGIN TRAN;
TRUNCATE TABLE gold.dim_user;
INSERT gold.dim_user (user_key, user_id, employee_name, email, role, business_unit, functional_unit,
                      department, team, supervisor, openness, conscientiousness, extraversion, agreeableness, neuroticism)
SELECT ROW_NUMBER() OVER (ORDER BY user_id), CONVERT(varchar(50), user_id), CONVERT(varchar(100), employee_name),
       CONVERT(varchar(100), email), CONVERT(varchar(50), role), CONVERT(varchar(50), business_unit),
       CONVERT(varchar(50), functional_unit), CONVERT(varchar(50), department), CONVERT(varchar(50), team),
       CONVERT(varchar(100), supervisor), O, C, E, A, N
FROM silver.dim_user;

TRUNCATE TABLE gold.fact_activity;
INSERT gold.fact_activity (activity_key, user_key, pc_key, activity_time, activity_type, activity_detail)
SELECT ROW_NUMBER() OVER (ORDER BY a.event_time, a.event_id), u.user_key, p.pc_key,
       a.event_time, LEFT(a.event_type, 6), LEFT(a.detail, 20)
FROM silver.activity a
LEFT JOIN gold.dim_user u ON u.user_id = a.[user]
LEFT JOIN gold.dim_pc   p ON p.pc_id   = a.pc;
COMMIT;
-- afterwards: python -m src.quality.run_checks   (fact_rows_equal_silver_activity must PASS)
*/
