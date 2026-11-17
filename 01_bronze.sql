-- Bronze layer
-- Generated from the project's SSMS script and made re-runnable (IF NOT EXISTS / CREATE OR ALTER).
USE InsiderThreat;
GO
-- Bronze: source data as received (text) + provenance (source_file, ingested_at).

IF OBJECT_ID(N'bronze.device', N'U') IS NULL
CREATE TABLE [bronze].[device](
	[id] [varchar](50) NULL,
	[event_date] [varchar](50) NULL,
	[user_id] [varchar](50) NULL,
	[pc] [varchar](50) NULL,
	[activity] [varchar](50) NULL,
	[source_file] [varchar](500) NULL,
	[ingested_at] [datetime2](7) NOT NULL
) ON [PRIMARY]
GO
IF OBJECT_ID(N'bronze.http_email_raw', N'U') IS NULL
CREATE TABLE [bronze].[http_email_raw](
	[line_id] [int] IDENTITY(1,1) NOT NULL,
	[source_file] [nvarchar](200) NULL,
	[line] [nvarchar](max) NULL,
	[ingested_at] [datetime2](7) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
IF OBJECT_ID(N'bronze.insiders', N'U') IS NULL
CREATE TABLE [bronze].[insiders](
	[line] [nvarchar](max) NULL,
	[source_file] [nvarchar](100) NULL,
	[ingested_at] [datetime2](7) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
IF OBJECT_ID(N'bronze.ldap', N'U') IS NULL
CREATE TABLE [bronze].[ldap](
	[employee_name] [nvarchar](200) NULL,
	[user_id] [nvarchar](50) NULL,
	[email] [nvarchar](200) NULL,
	[role] [nvarchar](100) NULL,
	[business_unit] [nvarchar](100) NULL,
	[functional_unit] [nvarchar](200) NULL,
	[department] [nvarchar](200) NULL,
	[team] [nvarchar](200) NULL,
	[supervisor] [nvarchar](200) NULL,
	[snapshot_month] [char](7) NULL,
	[source_file] [nvarchar](100) NULL,
	[snapshot_date] [date] NULL,
	[supervisor_clean] [nvarchar](200) NULL,
	[bronze_source] [nvarchar](100) NULL,
	[bronze_load_ts] [datetime2](7) NOT NULL
) ON [PRIMARY]
GO
IF OBJECT_ID(N'bronze.logon', N'U') IS NULL
CREATE TABLE [bronze].[logon](
	[id] [varchar](50) NULL,
	[event_date] [varchar](50) NULL,
	[user_id] [varchar](50) NULL,
	[pc] [varchar](50) NULL,
	[activity] [varchar](50) NULL,
	[source_file] [varchar](500) NULL,
	[ingested_at] [datetime2](7) NOT NULL
) ON [PRIMARY]
GO
IF OBJECT_ID(N'bronze.psychometric', N'U') IS NULL
CREATE TABLE [bronze].[psychometric](
	[employee_name] [nvarchar](200) NULL,
	[user_id] [nvarchar](50) NULL,
	[O] [decimal](5, 2) NULL,
	[C] [decimal](5, 2) NULL,
	[E] [decimal](5, 2) NULL,
	[A] [decimal](5, 2) NULL,
	[N] [decimal](5, 2) NULL,
	[source_file] [nvarchar](100) NULL,
	[ingested_at] [datetime2](7) NOT NULL
) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints dc JOIN sys.columns c ON c.object_id = dc.parent_object_id AND c.column_id = dc.parent_column_id WHERE dc.parent_object_id = OBJECT_ID(N'bronze.device') AND c.name = N'ingested_at')
ALTER TABLE [bronze].[device] ADD  DEFAULT (sysdatetime()) FOR [ingested_at]
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints dc JOIN sys.columns c ON c.object_id = dc.parent_object_id AND c.column_id = dc.parent_column_id WHERE dc.parent_object_id = OBJECT_ID(N'bronze.logon') AND c.name = N'ingested_at')
ALTER TABLE [bronze].[logon] ADD  DEFAULT (sysdatetime()) FOR [ingested_at]
GO
CREATE OR ALTER PROCEDURE [bronze].[load_device]
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;
  DECLARE @batch UNIQUEIDENTIFIER = NEWID(),
          @start DATETIME2 = SYSDATETIME(),
          @rows  BIGINT;
  BEGIN TRY
    TRUNCATE TABLE bronze.device;

    INSERT bronze.device (id, event_date, user_id, pc, activity, source_file)
    SELECT id, [date], [user], pc, activity, 'CERT r4.2 device (master.dbo.stg_device)'
    FROM master.dbo.stg_device;

    SELECT @rows = COUNT_BIG(*) FROM bronze.device;
    INSERT audit.load_log (batch_id, source_name, target_table, start_time, end_time, rows_loaded, status, message)
    VALUES (@batch, 'device', 'bronze.device', @start, SYSDATETIME(), @rows, 'SUCCESS', 'Bronze load');
  END TRY
  BEGIN CATCH
    INSERT audit.load_log (batch_id, source_name, target_table, start_time, end_time, rows_loaded, status, message)
    VALUES (@batch, 'device', 'bronze.device', @start, SYSDATETIME(), NULL, 'FAILED', ERROR_MESSAGE());
    THROW;
  END CATCH
END;
GO
CREATE OR ALTER PROCEDURE [bronze].[load_logon]
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;
  DECLARE @batch UNIQUEIDENTIFIER = NEWID(),
          @start DATETIME2 = SYSDATETIME(),
          @rows  BIGINT;
  BEGIN TRY
    TRUNCATE TABLE bronze.logon;

    INSERT bronze.logon (id, event_date, user_id, pc, activity, source_file)
    SELECT id, [date], [user], pc, activity, 'CERT r4.2 logon (master.dbo.stg_logon)'
    FROM master.dbo.stg_logon;

    SELECT @rows = COUNT_BIG(*) FROM bronze.logon;
    INSERT audit.load_log (batch_id, source_name, target_table, start_time, end_time, rows_loaded, status, message)
    VALUES (@batch, 'logon', 'bronze.logon', @start, SYSDATETIME(), @rows, 'SUCCESS', 'Bronze load');
  END TRY
  BEGIN CATCH
    INSERT audit.load_log (batch_id, source_name, target_table, start_time, end_time, rows_loaded, status, message)
    VALUES (@batch, 'logon', 'bronze.logon', @start, SYSDATETIME(), NULL, 'FAILED', ERROR_MESSAGE());
    THROW;
  END CATCH
END;
GO
-- BULK INSERT loads into these views so source_file / ingested_at keep their values (used by src/ingest/load_csv.py).
CREATE OR ALTER VIEW bronze.v_logon_load AS
SELECT id, event_date, user_id, pc, activity FROM bronze.logon;
GO
CREATE OR ALTER VIEW bronze.v_device_load AS
SELECT id, event_date, user_id, pc, activity FROM bronze.device;
GO
