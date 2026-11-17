# Project Specification: Insider Threat Data Warehouse

## Problem statement
Organizations lose data and money to malicious insiders: employees who abuse legitimate access. Security analysts cannot read millions of log lines, so they need one warehouse that joins logon, device and employee data, a trusted set of metrics, and a ranked list of users to review. This project builds that warehouse on the CERT Insider Threat Test Dataset r4.2 (1,000 users, 1,003 PCs) and trains a model that scores each user's risk. Users of the output: security analysts and HR/IT managers deciding whom to investigate.

## Business questions
1. How do malicious insiders differ from normal users (logons, after-hours logons, USB use, PCs, active days)? (`semantic.v_insider_vs_normal`)
2. Which attack scenario produces which behaviour? (`semantic.v_insider_by_scenario`)
3. How does activity change over time, by event type? (`semantic.v_activity_by_month`)
4. Which departments have the highest insider rate? (`semantic.v_risk_by_department`)
5. Which users should an analyst review first? (`ml.user_risk_score`)

## Source contract
See `data_source_register.csv`. Summary:

| Source | Native grain | Natural key | Timestamp | Volume in Bronze | Sensitive fields |
|---|---|---|---|---|---|
| logon | one logon/logoff event | id | date | 854,859 | user, pc |
| device | one device connect/disconnect | id | date | 405,380 | user, pc |
| LDAP | one employee per monthly snapshot | user_id + snapshot_month | snapshot_date | 32,486 | name, email, supervisor |
| psychometric | one employee | user_id | none | 1,000 | personality scores |
| insiders.csv | one insider per scenario | dataset + user | start, end | 192 lines | ground-truth label |
| http / answer files | one raw line | line_id | in the line | 6,765 lines | URLs |

Refresh assumption: the dataset is static (one historical release). Missing values and duplicates are handled in Silver; rejected rows go to `silver.reject_log` (0 rows rejected in the final load).

## Target entities
User (`gold.dim_user`), PC (`gold.dim_pc`), Activity event (`gold.fact_activity`), Insider ground truth (`silver.insiders`), User feature row (`gold.user_features`).

## Layers
- **Bronze:** copy of the source as text with provenance (`source_file`, `ingested_at`). No cleaning. `bronze.load_device` and `bronze.load_logon` log every run in `audit.load_log`.
- **Silver:** typed (`datetime2`, `decimal`), unified activity table `silver.activity` (event_type, detail, source, scenario, is_insider), user dimension merged from LDAP and psychometric data, clustered indexes on time, indexes on `(is_insider, scenario)` and `(user, event_time)`.
- **Gold:** star schema. Grain: `fact_activity` = one event, `dim_user` = one user, `dim_pc` = one PC, `user_features` = one user.
- **Semantic:** `metric_catalog` (filled from `semantic/metrics.yml`) and metric views `v_*`.
- **ML:** `ml.user_risk_score` and `ml.model_metrics`.

### Transformation rules (fill in before the demo, one line per rule)
| Step | Rule | Where |
|---|---|---|
| Bronze to Silver, dates | TODO: how text dates were converted | silver.logon / silver.device |
| Silver user dimension | TODO: how LDAP snapshots were reduced to one row per user | silver.dim_user |
| Unified activity | TODO: how logon/device (and other events) were mapped to event_type and detail | silver.activity |
| Insider label | TODO: how `is_insider` and `scenario` were derived from insiders.csv | silver.activity, gold.user_features |
| After-hours logon | TODO: working-hours window used | gold.user_features |

## Integration challenges to solve
Key reconciliation across sources (`user_id` appears in logon, LDAP, psychometric and insiders), LDAP snapshots (many rows per user), time alignment (insider start/end dates against event time), raw text dates, duplicates, provenance. Open points are listed in `KNOWN_ISSUES.md`.

## SQL checklist
Joins across sources, CTEs, window functions, conditional aggregation, data-quality queries (`src/quality/checks.sql`), temporal analysis (`v_activity_by_month`), dimensional loading, feature views, semantic metric views, metrics reconciled with an independent validation query (`semantic/metrics.yml`).

## Mining checklist
Feature view `gold.features_user_model` (and `gold.features_user`). Baseline logistic regression versus random forest on a stratified hold-out split; metrics precision, recall, F1, ROC-AUC and PR-AUC (PR-AUC matters because insiders are rare). Outputs in `ml.user_risk_score` with `user_id`, `risk_score`, `predicted_label`, `data_split`, `model_name`, `model_version`, `run_id`, `generated_at`. Leakage guard for features that are zero for all normal users.

## Testing
`pytest` (metric YAML, model code on synthetic data) and `python -m src.quality.run_checks` (uniqueness, referential integrity, source-to-target reconciliation, accepted ranges, label values, model-output completeness).

## Milestones
M1 problem and sources. M2 Bronze and profiling. M3 Silver and quality. M4 Gold and semantic layer. M5 mining. M6 dashboard or app. M7 report and demo.

## Team
TODO: names and roles (needed for the `owner` field of each metric).

## Marking (set by the instructor)
TODO: copy the criteria and marks from the assignment brief.
