-- Business queries. Each starts with the question and the grain of the result.
USE InsiderThreat;

-- Q1: How do insiders differ from normal users? Grain: one row per is_insider value.
SELECT * FROM semantic.v_insider_vs_normal;

-- Q2: Which attack scenario produces the most USB activity? Grain: one row per scenario.
SELECT scenario, insiders, avg_usb_connects FROM semantic.v_insider_by_scenario ORDER BY avg_usb_connects DESC;

-- Q3: How does activity change over time? Grain: one row per month and event type.
SELECT year_number, month_number, event_type, event_count
FROM semantic.v_activity_by_month ORDER BY year_number, month_number, event_type;

-- Q4: Which departments have the highest insider rate? Grain: one row per department.
SELECT TOP 10 department, users, insiders, insider_rate FROM semantic.v_risk_by_department ORDER BY insider_rate DESC;

-- Q5: Who are the 20 highest-risk users according to the model? Grain: one row per user.
SELECT TOP 20 r.user_id, r.risk_score, r.actual_label, r.data_split, u.department, u.role
FROM ml.user_risk_score r
JOIN gold.user_features u ON u.user_id = r.user_id
WHERE r.run_id = (SELECT TOP 1 run_id FROM ml.model_metrics ORDER BY generated_at DESC)
  AND r.model_name = 'random_forest'
ORDER BY r.risk_score DESC;
