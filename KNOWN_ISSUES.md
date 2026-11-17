# Known issues and limitations (read before presenting)

Evidence below comes from the row counts of the final database. Items marked **verify** need one query on your machine.

## 1. gold.fact_activity is about 33x larger than silver.activity (fix available)
| Table | Rows |
|---|---|
| silver.activity | 1,264,397 |
| gold.fact_activity | 42,147,175 |
| silver.dim_user | 1,000 |
| gold.dim_user | 32,486 |

`gold.fact_activity` should have one row per event, so it should equal `silver.activity`. `gold.dim_user` has 32,486 rows, the same number as the LDAP snapshots (`silver.ldap`), instead of one row per user (1,000). The likely cause is that the fact was joined to a user dimension built from LDAP snapshots, repeating every event once per snapshot. **Verify** with step 1 of `sql/08_fix_gold_grain.sql`. The same script rebuilds both tables (step 2, commented out). The metric views read `gold.user_features` and `silver.activity`, so they do not depend on this table. `fact_rows_equal_silver_activity` in `checks.sql` fails until it is fixed.

## 2. Possible label leakage in http/email features (verify)
`bronze.http_email_raw` has only 6,765 lines. If these come from the insider answer files, `http_events` and `email_events` in `gold.user_features` are non-zero only for insiders, and a model would learn the label instead of behaviour. Verify:
```sql
SELECT is_insider, SUM(http_events) AS http_events, SUM(email_events) AS email_events
FROM gold.user_features GROUP BY is_insider;
```
If normal users have zero, `src/mining/baseline.py` drops those features automatically and prints a warning. State this limitation in the report.

## 3. insiders.csv covers several dataset versions
`silver.insiders` has 191 rows. Filter on `dataset` for r4.2 when you count insiders: `SELECT dataset, COUNT(DISTINCT [user]) FROM silver.insiders GROUP BY dataset`. The metric `insider_count` validates against this.

## 4. Loading depends on master.dbo.stg_*
`bronze.load_device` and `bronze.load_logon` read the staging tables `master.dbo.stg_device` / `stg_logon`. The original CSV files were deleted from the machine after loading. Bronze already holds the data, so do not re-run the Bronze procedures (they TRUNCATE first). `src/ingest/load_csv.py` reloads Bronze from the CSV files if you download them again.

## 5. Not implemented
Silver and Gold load procedures: Silver and Gold were populated outside these scripts, so their transformation rules are not versioned here. Document the rules you used before the demo (see "Transformation rules" in `PROJECT_SPEC.md`). `silver.reject_log` is empty: no row was rejected.
