-- ML outputs written back from Python (SQL -> Python -> SQL).
USE InsiderThreat;
GO
IF OBJECT_ID(N'ml.user_risk_score', N'U') IS NULL
CREATE TABLE ml.user_risk_score (
  user_id         NVARCHAR(50) NOT NULL,
  risk_score      FLOAT        NOT NULL,   -- predicted probability of being an insider
  predicted_label INT          NOT NULL,
  actual_label    INT          NULL,
  data_split      VARCHAR(5)   NOT NULL,   -- train / test
  model_name      VARCHAR(50)  NOT NULL,
  model_version   VARCHAR(20)  NOT NULL,
  run_id          VARCHAR(36)  NOT NULL,
  generated_at    DATETIME2    NOT NULL
);
GO
IF OBJECT_ID(N'ml.model_metrics', N'U') IS NULL
CREATE TABLE ml.model_metrics (
  run_id        VARCHAR(36)  NOT NULL,
  model_name    VARCHAR(50)  NOT NULL,
  model_version VARCHAR(20)  NOT NULL,
  metric_name   VARCHAR(50)  NOT NULL,
  metric_value  FLOAT        NULL,
  generated_at  DATETIME2    NOT NULL
);
GO
