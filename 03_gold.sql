-- Gold layer
-- Generated from the project's SSMS script and made re-runnable (IF NOT EXISTS / CREATE OR ALTER).
USE InsiderThreat;
GO
-- GRAINS
-- gold.dim_user       : one row per user (user_id).   Expected 1000 rows.
-- gold.dim_pc         : one row per PC (pc_id).
-- gold.fact_activity  : one row per activity event = one row of silver.activity.
-- gold.user_features  : one row per user (training table for the ML task, label = is_insider).
-- gold.features_user  : view, one row per user (counts per activity type + personality).

IF OBJECT_ID(N'gold.dim_user', N'U') IS NULL
CREATE TABLE [gold].[dim_user](
	[user_key] [bigint] NULL,
	[user_id] [varchar](50) NULL,
	[employee_name] [varchar](100) NULL,
	[email] [varchar](100) NULL,
	[role] [varchar](50) NULL,
	[business_unit] [varchar](50) NULL,
	[functional_unit] [varchar](50) NULL,
	[department] [varchar](50) NULL,
	[team] [varchar](50) NULL,
	[supervisor] [varchar](100) NULL,
	[openness] [float] NULL,
	[conscientiousness] [float] NULL,
	[extraversion] [float] NULL,
	[agreeableness] [float] NULL,
	[neuroticism] [float] NULL
) ON [PRIMARY]
GO
IF OBJECT_ID(N'gold.fact_activity', N'U') IS NULL
CREATE TABLE [gold].[fact_activity](
	[activity_key] [bigint] NULL,
	[user_key] [bigint] NULL,
	[pc_key] [bigint] NULL,
	[activity_time] [datetime2](7) NULL,
	[activity_type] [varchar](6) NOT NULL,
	[activity_detail] [varchar](20) NULL
) ON [PRIMARY]
GO
IF OBJECT_ID(N'gold.dim_pc', N'U') IS NULL
CREATE TABLE [gold].[dim_pc](
	[pc_key] [bigint] NULL,
	[pc_id] [varchar](50) NULL
) ON [PRIMARY]
GO
IF OBJECT_ID(N'gold.user_features', N'U') IS NULL
CREATE TABLE [gold].[user_features](
	[user_id] [nvarchar](50) NULL,
	[role] [nvarchar](100) NULL,
	[department] [nvarchar](200) NULL,
	[O] [decimal](5, 2) NULL,
	[C] [decimal](5, 2) NULL,
	[E] [decimal](5, 2) NULL,
	[A] [decimal](5, 2) NULL,
	[N] [decimal](5, 2) NULL,
	[is_insider] [int] NOT NULL,
	[scenario] [int] NULL,
	[total_events] [int] NULL,
	[logons] [int] NULL,
	[after_hours_logons] [int] NULL,
	[usb_connects] [int] NULL,
	[http_events] [int] NULL,
	[email_events] [int] NULL,
	[distinct_pcs] [int] NULL,
	[active_days] [int] NULL
) ON [PRIMARY]
GO
-- 4. Gold Features View: تجهيز الـ Features الخاصة بالموديل
CREATE OR ALTER VIEW [gold].[features_user] AS
SELECT 
    u.user_key,
    u.user_id,
    COUNT(f.activity_key) AS total_activities,
    SUM(CASE WHEN f.activity_type = 'device' THEN 1 ELSE 0 END) AS total_device_events,
    SUM(CASE WHEN f.activity_type = 'logon' THEN 1 ELSE 0 END) AS total_logon_events,
    u.openness,
    u.conscientiousness,
    u.extraversion,
    u.agreeableness,
    u.neuroticism
FROM gold.dim_user u
LEFT JOIN gold.fact_activity f ON u.user_key = f.user_key
GROUP BY 
    u.user_key, u.user_id, 
    u.openness, u.conscientiousness, u.extraversion, u.agreeableness, u.neuroticism;
GO
