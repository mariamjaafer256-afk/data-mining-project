-- Run in SSMS. Needs SQL Server 2017 or later.
-- Creates the database (default file locations) and the six layer schemas. Safe to re-run.
IF DB_ID('InsiderThreat') IS NULL CREATE DATABASE InsiderThreat;
GO
USE InsiderThreat;
GO
IF SCHEMA_ID('bronze')   IS NULL EXEC('CREATE SCHEMA bronze');
IF SCHEMA_ID('silver')   IS NULL EXEC('CREATE SCHEMA silver');
IF SCHEMA_ID('gold')     IS NULL EXEC('CREATE SCHEMA gold');
IF SCHEMA_ID('semantic') IS NULL EXEC('CREATE SCHEMA semantic');
IF SCHEMA_ID('ml')       IS NULL EXEC('CREATE SCHEMA ml');
IF SCHEMA_ID('audit')    IS NULL EXEC('CREATE SCHEMA audit');
GO
-- One row per pipeline run, written by every load procedure.
IF OBJECT_ID('audit.load_log') IS NULL
CREATE TABLE audit.load_log (
  load_id      BIGINT IDENTITY(1,1) PRIMARY KEY,
  batch_id     UNIQUEIDENTIFIER NOT NULL,
  source_name  VARCHAR(100) NOT NULL,
  target_table VARCHAR(200) NOT NULL,
  start_time   DATETIME2 NOT NULL,
  end_time     DATETIME2 NULL,
  rows_loaded  BIGINT NULL,
  status       VARCHAR(20) NOT NULL,
  message      VARCHAR(4000) NULL
);
GO
