# Architecture

```mermaid
flowchart LR
    subgraph SRC[Sources: CERT r4.2]
        A1[logon.csv]:::s
        A2[device.csv]:::s
        A3[LDAP monthly]:::s
        A4[psychometric.csv]:::s
        A5[insiders.csv]:::s
        A6[http / answer files]:::s
    end
    A1 & A2 --> B1[bronze.logon / bronze.device]
    A3 --> B2[bronze.ldap]
    A4 --> B3[bronze.psychometric]
    A5 --> B4[bronze.insiders]
    A6 --> B5[bronze.http_email_raw]
    B1 & B2 & B3 & B4 & B5 --> S[silver: typed, cleaned<br/>activity, dim_user, insiders, reject_log]
    S --> G[gold: dim_user, dim_pc, fact_activity<br/>user_features, features_user]
    G --> M[semantic: metric_catalog + v_* views]
    G --> ML[Python baseline<br/>logreg vs random forest]
    ML --> O[ml.user_risk_score<br/>ml.model_metrics]
    M --> BI[SQL analytics / dashboard]
    O --> BI
    L[(audit.load_log)] -.-> B1
    classDef s fill:#eee,stroke:#999;
```

| Layer | Schema | Row counts (final database) |
|---|---|---|
| Bronze | `bronze` | device 405,380 / logon 854,859 / ldap 32,486 / psychometric 1,000 / insiders 192 / http_email_raw 6,765 |
| Silver | `silver` | device 405,380 / logon 854,859 / ldap 32,486 / psychometric 1,000 / dim_user 1,000 / insiders 191 / activity 1,264,397 / reject_log 0 |
| Gold | `gold` | dim_user 32,486 (should be 1,000, see KNOWN_ISSUES) / dim_pc 1,003 / fact_activity 42,147,175 (should equal silver.activity) / user_features 1,000 |
| Semantic | `semantic` | metric_catalog + 5 metric views |
| ML | `ml` | user_risk_score, model_metrics |
| Audit | `audit` | load_log |
