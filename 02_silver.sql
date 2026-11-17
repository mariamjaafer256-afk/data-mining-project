-- Silver layer
-- Generated from the project's SSMS script and made re-runnable (IF NOT EXISTS / CREATE OR ALTER).
USE InsiderThreat;
GO
-- Silver: typed and cleaned. silver.activity = unified event table (logon + device + others).

IF OBJECT_ID(N'silver.activity', N'U') IS NULL
CREATE TABLE [silver].[activity](
	[event_id] [nvarchar](50) NULL,
	[event_time] [datetime] NULL,
	[user] [nvarchar](50) NULL,
	[pc] [nvarchar](50) NULL,
	[event_type] [varchar](10) NULL,
	[detail] [nvarchar](max) NULL,
	[source] [varchar](12) NOT NULL,
	[scenario] [int] NULL,
	[is_insider] [bit] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
IF OBJECT_ID(N'silver.device', N'U') IS NULL
CREATE TABLE [silver].[device](
	[device_id] [varchar](50) NULL,
	[device_time] [datetime2](7) NULL,
	[user_id] [varchar](50) NULL,
	[pc] [varchar](50) NULL,
	[activity] [varchar](20) NULL
) ON [PRIMARY]
GO
IF OBJECT_ID(N'silver.dim_user', N'U') IS NULL
CREATE TABLE [silver].[dim_user](
	[user_id] [nvarchar](50) NULL,
	[employee_name] [nvarchar](200) NULL,
	[email] [nvarchar](200) NULL,
	[role] [nvarchar](100) NULL,
	[business_unit] [nvarchar](100) NULL,
	[functional_unit] [nvarchar](200) NULL,
	[department] [nvarchar](200) NULL,
	[team] [nvarchar](200) NULL,
	[supervisor] [nvarchar](200) NULL,
	[O] [decimal](5, 2) NULL,
	[C] [decimal](5, 2) NULL,
	[E] [decimal](5, 2) NULL,
	[A] [decimal](5, 2) NULL,
	[N] [decimal](5, 2) NULL
) ON [PRIMARY]
GO
IF OBJECT_ID(N'silver.insiders', N'U') IS NULL
CREATE TABLE [silver].[insiders](
	[dataset] [nvarchar](10) NULL,
	[scenario] [int] NULL,
	[details] [nvarchar](100) NULL,
	[user] [nvarchar](20) NULL,
	[start_dt] [datetime] NULL,
	[end_dt] [datetime] NULL
) ON [PRIMARY]
GO
IF OBJECT_ID(N'silver.ldap', N'U') IS NULL
CREATE TABLE [silver].[ldap](
	[employee_name] [varchar](100) NULL,
	[user_id] [varchar](50) NULL,
	[email] [varchar](100) NULL,
	[role] [varchar](50) NULL,
	[business_unit] [varchar](50) NULL,
	[functional_unit] [varchar](50) NULL,
	[department] [varchar](50) NULL,
	[team] [varchar](50) NULL,
	[supervisor] [varchar](100) NULL
) ON [PRIMARY]
GO
IF OBJECT_ID(N'silver.logon', N'U') IS NULL
CREATE TABLE [silver].[logon](
	[logon_id] [varchar](50) NULL,
	[logon_time] [datetime2](7) NULL,
	[user_id] [varchar](50) NULL,
	[pc] [varchar](50) NULL,
	[activity] [varchar](20) NULL
) ON [PRIMARY]
GO
IF OBJECT_ID(N'silver.psychometric', N'U') IS NULL
CREATE TABLE [silver].[psychometric](
	[employee_name] [varchar](100) NULL,
	[user_id] [varchar](50) NULL,
	[openness] [float] NULL,
	[conscientiousness] [float] NULL,
	[extraversion] [float] NULL,
	[agreeableness] [float] NULL,
	[neuroticism] [float] NULL
) ON [PRIMARY]
GO
IF OBJECT_ID(N'silver.reject_log', N'U') IS NULL
CREATE TABLE [silver].[reject_log](
	[reject_id] [int] IDENTITY(1,1) NOT NULL,
	[source_table] [varchar](100) NULL,
	[row_data] [varchar](max) NULL,
	[reason] [varchar](255) NULL,
	[rejected_at] [datetime2](7) NULL,
PRIMARY KEY CLUSTERED 
(
	[reject_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_silver_device_time' AND object_id = OBJECT_ID(N'silver.device'))
CREATE CLUSTERED INDEX [IX_silver_device_time] ON [silver].[device]
(
	[device_time] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_silver_logon_time' AND object_id = OBJECT_ID(N'silver.logon'))
CREATE CLUSTERED INDEX [IX_silver_logon_time] ON [silver].[logon]
(
	[logon_time] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'ix_master_insider' AND object_id = OBJECT_ID(N'silver.activity'))
CREATE NONCLUSTERED INDEX [ix_master_insider] ON [silver].[activity]
(
	[is_insider] ASC,
	[scenario] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'ix_master_user_time' AND object_id = OBJECT_ID(N'silver.activity'))
CREATE NONCLUSTERED INDEX [ix_master_user_time] ON [silver].[activity]
(
	[user] ASC,
	[event_time] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints dc JOIN sys.columns c ON c.object_id = dc.parent_object_id AND c.column_id = dc.parent_column_id WHERE dc.parent_object_id = OBJECT_ID(N'silver.activity') AND c.name = N'is_insider')
ALTER TABLE [silver].[activity] ADD  DEFAULT ((0)) FOR [is_insider]
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints dc JOIN sys.columns c ON c.object_id = dc.parent_object_id AND c.column_id = dc.parent_column_id WHERE dc.parent_object_id = OBJECT_ID(N'silver.reject_log') AND c.name = N'rejected_at')
ALTER TABLE [silver].[reject_log] ADD  DEFAULT (sysdatetime()) FOR [rejected_at]
GO
