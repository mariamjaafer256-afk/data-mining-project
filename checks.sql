-- Each check must return ZERO rows to PASS. Start every check with "-- check: name".

-- ===== Bronze -> Silver reconciliation (bronze = silver + rejected) =====
-- check: logon_bronze_equals_silver_plus_rejected
SELECT 'mismatch' AS problem
WHERE (SELECT COUNT_BIG(*) FROM bronze.logon)
   <> (SELECT COUNT_BIG(*) FROM silver.logon) + (SELECT COUNT_BIG(*) FROM silver.reject_log WHERE source_table LIKE '%logon%');

-- check: device_bronze_equals_silver_plus_rejected
SELECT 'mismatch' AS problem
WHERE (SELECT COUNT_BIG(*) FROM bronze.device)
   <> (SELECT COUNT_BIG(*) FROM silver.device) + (SELECT COUNT_BIG(*) FROM silver.reject_log WHERE source_table LIKE '%device%');

-- check: ldap_bronze_equals_silver_plus_rejected
SELECT 'mismatch' AS problem
WHERE (SELECT COUNT_BIG(*) FROM bronze.ldap)
   <> (SELECT COUNT_BIG(*) FROM silver.ldap) + (SELECT COUNT_BIG(*) FROM silver.reject_log WHERE source_table LIKE '%ldap%');

-- check: psychometric_bronze_equals_silver_plus_rejected
SELECT 'mismatch' AS problem
WHERE (SELECT COUNT_BIG(*) FROM bronze.psychometric)
   <> (SELECT COUNT_BIG(*) FROM silver.psychometric) + (SELECT COUNT_BIG(*) FROM silver.reject_log WHERE source_table LIKE '%psychometric%');

-- check: insiders_bronze_minus_header_equals_silver
SELECT 'mismatch' AS problem
WHERE (SELECT COUNT_BIG(*) FROM bronze.insiders WHERE line NOT LIKE 'dataset,%')
   <> (SELECT COUNT_BIG(*) FROM silver.insiders);

-- ===== Uniqueness =====
-- check: silver_dim_user_unique_user_id
SELECT user_id FROM silver.dim_user GROUP BY user_id HAVING COUNT(*) > 1;

-- check: gold_dim_user_unique_user_id
SELECT user_id FROM gold.dim_user GROUP BY user_id HAVING COUNT(*) > 1;

-- check: gold_dim_pc_unique_pc_id
SELECT pc_id FROM gold.dim_pc GROUP BY pc_id HAVING COUNT(*) > 1;

-- check: gold_user_features_unique_user_id
SELECT user_id FROM gold.user_features GROUP BY user_id HAVING COUNT(*) > 1;

-- ===== Silver -> Gold reconciliation and referential integrity =====
-- check: fact_rows_equal_silver_activity
SELECT 'mismatch' AS problem
WHERE (SELECT COUNT_BIG(*) FROM gold.fact_activity) <> (SELECT COUNT_BIG(*) FROM silver.activity);

-- check: fact_no_orphan_user_keys
SELECT TOP 100 activity_key FROM gold.fact_activity WHERE user_key IS NULL;

-- check: fact_no_orphan_pc_keys
SELECT TOP 100 activity_key FROM gold.fact_activity WHERE pc_key IS NULL;

-- ===== Accepted ranges and completeness =====
-- check: psychometric_scores_in_range
SELECT user_id FROM silver.psychometric
WHERE openness NOT BETWEEN 0 AND 100 OR conscientiousness NOT BETWEEN 0 AND 100
   OR extraversion NOT BETWEEN 0 AND 100 OR agreeableness NOT BETWEEN 0 AND 100 OR neuroticism NOT BETWEEN 0 AND 100;

-- check: user_features_label_is_binary
SELECT user_id FROM gold.user_features WHERE is_insider NOT IN (0, 1);

-- check: user_features_counts_not_negative
SELECT user_id FROM gold.user_features
WHERE total_events < 0 OR logons < 0 OR usb_connects < 0 OR after_hours_logons > logons;

-- check: every_user_has_a_feature_row
SELECT user_id FROM silver.dim_user WHERE user_id NOT IN (SELECT user_id FROM gold.user_features);

-- ===== Model output completeness (passes once src.mining.baseline has run) =====
-- check: model_output_has_all_users
SELECT 'mismatch' AS problem
WHERE (SELECT COUNT(DISTINCT user_id) FROM ml.user_risk_score) <> (SELECT COUNT(*) FROM gold.user_features);
