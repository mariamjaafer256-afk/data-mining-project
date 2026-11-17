-- Semantic layer: metric catalog (filled from semantic/metrics.yml) and metric views.
USE InsiderThreat;
GO
IF OBJECT_ID(N'semantic.metric_catalog', N'U') IS NULL
CREATE TABLE semantic.metric_catalog (
  metric_id         INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  metric_name       VARCHAR(100) NULL,
  description       VARCHAR(255) NULL,
  calculation_logic VARCHAR(MAX) NULL,
  created_at        DATETIME2 NULL DEFAULT SYSDATETIME()
);
GO
-- Extend the catalog to the course template (adds only the missing columns, keeps existing rows).
IF COL_LENGTH('semantic.metric_catalog','label')            IS NULL ALTER TABLE semantic.metric_catalog ADD label            VARCHAR(200)  NULL;
IF COL_LENGTH('semantic.metric_catalog','definition')       IS NULL ALTER TABLE semantic.metric_catalog ADD definition       VARCHAR(1000) NULL;
IF COL_LENGTH('semantic.metric_catalog','owner')            IS NULL ALTER TABLE semantic.metric_catalog ADD owner            VARCHAR(100)  NULL;
IF COL_LENGTH('semantic.metric_catalog','grain')            IS NULL ALTER TABLE semantic.metric_catalog ADD grain            VARCHAR(200)  NULL;
IF COL_LENGTH('semantic.metric_catalog','sql_expression')   IS NULL ALTER TABLE semantic.metric_catalog ADD sql_expression   VARCHAR(1000) NULL;
IF COL_LENGTH('semantic.metric_catalog','dimensions')       IS NULL ALTER TABLE semantic.metric_catalog ADD dimensions       VARCHAR(500)  NULL;
IF COL_LENGTH('semantic.metric_catalog','null_policy')      IS NULL ALTER TABLE semantic.metric_catalog ADD null_policy      VARCHAR(500)  NULL;
IF COL_LENGTH('semantic.metric_catalog','validation_query') IS NULL ALTER TABLE semantic.metric_catalog ADD validation_query VARCHAR(2000) NULL;
IF COL_LENGTH('semantic.metric_catalog','updated_at')       IS NULL ALTER TABLE semantic.metric_catalog ADD updated_at       DATETIME2     NULL;
GO

-- Existing view from the project.
CREATE OR ALTER VIEW [semantic].[v_user_risk_summary] AS
SELECT 
    u.user_id,
    u.employee_name,
    u.department,
    u.role,
    f.total_activities,
    f.total_device_events,
    f.total_logon_events,
    u.openness,
    u.conscientiousness,
    u.neuroticism
FROM gold.dim_user u
LEFT JOIN gold.features_user f ON u.user_key = f.user_key;
GO

-- Metric views: one per business question. They read gold.user_features (one row per user) and silver.activity,
-- NOT gold.fact_activity, so results do not depend on the fact table's join fan-out (see docs/KNOWN_ISSUES.md).

-- Q: How do insiders differ from normal users?  Grain: one row per is_insider value.
CREATE OR ALTER VIEW semantic.v_insider_vs_normal AS
SELECT is_insider,
       COUNT(*)                                   AS users,
       AVG(CAST(total_events AS float))           AS avg_total_events,
       AVG(CAST(logons AS float))                 AS avg_logons,
       AVG(CAST(after_hours_logons AS float))     AS avg_after_hours_logons,
       AVG(CAST(usb_connects AS float))           AS avg_usb_connects,
       AVG(CAST(distinct_pcs AS float))           AS avg_distinct_pcs,
       AVG(CAST(active_days AS float))            AS avg_active_days
FROM gold.user_features
GROUP BY is_insider;
GO
-- Q: How do the attack scenarios differ?  Grain: one row per scenario (insiders only).
CREATE OR ALTER VIEW semantic.v_insider_by_scenario AS
SELECT scenario,
       COUNT(*)                               AS insiders,
       AVG(CAST(usb_connects AS float))       AS avg_usb_connects,
       AVG(CAST(after_hours_logons AS float)) AS avg_after_hours_logons,
       AVG(CAST(total_events AS float))       AS avg_total_events
FROM gold.user_features
WHERE is_insider = 1
GROUP BY scenario;
GO
-- Q: How does activity evolve over time?  Grain: one row per month and event type.
CREATE OR ALTER VIEW semantic.v_activity_by_month AS
SELECT YEAR(event_time)  AS year_number,
       MONTH(event_time) AS month_number,
       event_type,
       COUNT_BIG(*)      AS event_count
FROM silver.activity
GROUP BY YEAR(event_time), MONTH(event_time), event_type;
GO
-- Q: Which departments carry the most risk?  Grain: one row per department.
CREATE OR ALTER VIEW semantic.v_risk_by_department AS
SELECT department,
       COUNT(*)                                       AS users,
       SUM(is_insider)                                AS insiders,
       CAST(SUM(is_insider) AS float) / COUNT(*)      AS insider_rate,
       AVG(CAST(after_hours_logons AS float))         AS avg_after_hours_logons
FROM gold.user_features
GROUP BY department;
GO
