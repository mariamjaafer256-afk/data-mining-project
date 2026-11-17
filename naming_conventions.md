# Naming conventions
- Schemas, tables, columns: lowercase_snake_case.
- Keys: `<entity>_id` is a business key, `<entity>_key` is a surrogate key.
- Gold: `dim_<entity>`, `fact_<event>`, `features_<topic>`. Semantic views: `v_<metric_or_topic>`.
- ML outputs: `ml.<topic>_<result>`.
- Scripts: two-digit prefix and an action, for example `02_silver.sql`.
- Technical column: `DW_create_date` is when the pipeline wrote the row.
