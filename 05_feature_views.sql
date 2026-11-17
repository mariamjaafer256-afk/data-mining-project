-- ML reads ONLY documented feature sources. One row per user.
--   gold.user_features : training table (label = is_insider, scenario = attack type)
--   gold.features_user : view with event counts per type + personality (see 03_gold.sql)
-- Feature view used by src/mining/baseline.py: numeric features of gold.user_features.
USE InsiderThreat;
GO
CREATE OR ALTER VIEW gold.features_user_model AS
SELECT user_id, is_insider, scenario,
       total_events, logons, after_hours_logons, usb_connects, http_events, email_events,
       distinct_pcs, active_days,
       CAST(O AS float) AS O, CAST(C AS float) AS C, CAST(E AS float) AS E,
       CAST(A AS float) AS A, CAST(N AS float) AS N
FROM gold.user_features;
GO
