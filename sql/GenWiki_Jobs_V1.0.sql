/****************************************************************************
*              Confluence Wiki SQL代理作业文档生成工具 V1.0                 *
****************************************************************************/
SET NOCOUNT ON
GO
DECLARE @wikixml xml, @wiki nvarchar(max);
DECLARE @JobName nvarchar(200), @Server nvarchar(100);
/****************************************************************************
生成所有作业的列表：
	SET @JobName = ''
生成作业名为“XYZ”的页面：
	SET @JobName = 'XYZ'
****************************************************************************/

SET @JobName = ''

SET @Server = '192.168.'




/****************************************************************************
以下代码不要更改
****************************************************************************/
IF @JobName = ''
BEGIN
PRINT 'h1. 说明
----
'+REPLACE(@Server,'_','\_')+' 的SQL代理作业
按时间顺序列出

h1. SQL代理作业列表
----
|| 日期 || 时间 || 作业名 ||'
SET @wikixml = '<s>'+
STUFF((
SELECT
	CHAR(10)+'| '+
	CASE
		WHEN s.freq_type = 4 THEN '每'+ISNULL(CAST(NULLIF(s.freq_interval,1) AS nvarchar(10)),'')+'天'
		WHEN s.freq_type = 8 THEN '每周'+
			CASE WHEN s.freq_interval & 1 > 0 THEN '0' ELSE '' END+
			CASE WHEN s.freq_interval & 2 > 0 THEN '1' ELSE '' END+
			CASE WHEN s.freq_interval & 4 > 0 THEN '2' ELSE '' END+
			CASE WHEN s.freq_interval & 8 > 0 THEN '3' ELSE '' END+
			CASE WHEN s.freq_interval & 16 > 0 THEN '4' ELSE '' END+
			CASE WHEN s.freq_interval & 32 > 0 THEN '5' ELSE '' END+
			CASE WHEN s.freq_interval & 64 > 0 THEN '6' ELSE '' END
		ELSE 'unknown' END+' | '+
	CASE
		WHEN s.freq_subday_type = 1 THEN STUFF(LEFT(RIGHT('00000'+CAST(s.active_start_time AS nvarchar(10)),6),4),3,0,':')
		ELSE CASE WHEN s.active_start_time = 0 AND s.active_end_time = 235959 THEN ''
			ELSE STUFF(LEFT(RIGHT('00000'+CAST(s.active_start_time AS nvarchar(10)),6),4),3,0,':')+'到'+STUFF(LEFT(RIGHT('00000'+CAST(s.active_end_time AS nvarchar(10)),6),4),3,0,':')+'期间'
			END+
			'每'+CAST(s.freq_subday_interval AS nvarchar(10))+CASE
			WHEN s.freq_subday_type = 2 THEN '秒'
			WHEN s.freq_subday_type = 4 THEN '分钟'
			WHEN s.freq_subday_type = 8 THEN '小时' END
		END+' | ['+
	REPLACE(REPLACE(REPLACE(j.name,':','：'),'@','＠'),'|','｜')+'] |'
FROM msdb.dbo.sysjobschedules js
INNER JOIN msdb.dbo.sysschedules s
ON js.schedule_id = s.schedule_id
	AND s.enabled = 1
INNER JOIN msdb.dbo.sysjobs j
ON js.job_id = j.job_id
	AND j.enabled = 1
ORDER BY s.freq_type,
	CASE WHEN s.freq_subday_type = 1 THEN 99 ELSE s.freq_subday_type END,
	CASE WHEN s.freq_subday_type = 1 THEN 0 ELSE s.freq_subday_interval END,
	s.active_start_time,
	j.name
FOR XML PATH('')),1,1,'')+'</s>'
SET @wiki = @wikixml.value('/s[1]','nvarchar(max)')
DECLARE @len int
SET @len = LEN(@wiki) + 1
IF @len <= 4000
BEGIN
	PRINT @wiki
END
ELSE
BEGIN
	SET @wiki = REPLACE(@wiki,CHAR(13)+CHAR(10),CHAR(10))
	DECLARE @tmp nvarchar(4000)
	DECLARE @lnb int,@lne int
	SET @lnb = 1
	SET @tmp = ''
	WHILE @lnb < @len
	BEGIN
		SET @lne = ISNULL(NULLIF(CHARINDEX(CHAR(10),@wiki,@lnb),0),@len)
		IF @lnb = @lne
		BEGIN
			SET @tmp = @tmp + CHAR(13)+CHAR(10)
		END
		ELSE
		BEGIN
			SET @tmp = @tmp + SUBSTRING(@wiki,@lnb,@lne-@lnb)
			PRINT @tmp
			SET @tmp = ''
		END
		SET @lnb = @lne + 1
	END
END
END

ELSE
BEGIN
DECLARE @JobID uniqueidentifier
SET @JobID = (SELECT j.job_id FROM msdb.dbo.sysjobs j WHERE j.name = @JobName)

IF @JobID IS NOT NULL
BEGIN
DECLARE @JobDesc nvarchar(512)
SET @JobDesc = (SELECT j.description FROM msdb.dbo.sysjobs j WHERE j.name = @JobName)
 
PRINT 'h1. 说明
----
'+REPLACE(@JobDesc,'_','\_')+'
负责人：

h1. 作业步骤
----
|| 步骤 || 步骤名 || 类别 || 成功时 || 失败时 || 重试设定 || 操作 ||'
SET @wikixml = '<s>'+
STUFF((
SELECT
	CHAR(10)+'| '+
	CAST(step_id AS nvarchar(10))+' | '+
	REPLACE(REPLACE(REPLACE(step_name,'_','\_'),'[','\['),']','\]')+' | '+
	subsystem+' | '+
	CASE on_success_action
		WHEN 1 THEN '成功后退出'
		WHEN 3 THEN '转到下一步'
		WHEN 4 THEN '转到步骤'+CAST(on_success_step_id AS nvarchar(10))
		ELSE '' END+' | '+
	CASE on_fail_action
		WHEN 2 THEN '失败后退出'
		WHEN 3 THEN '转到下一步'
		WHEN 4 THEN '转到步骤'+CAST(on_fail_step_id AS nvarchar(10))
		ELSE '' END+' | '+
	CASE WHEN retry_attempts > 0 THEN '重试'+CAST(retry_attempts AS nvarchar(10))+'次，间隔'+CAST(retry_interval AS nvarchar(10))+'分钟'
		ELSE '不重试' END+' | '+
	CASE subsystem
		WHEN 'SSIS' THEN
			CASE WHEN command LIKE '/SQL "\etl_framework_v2_5_main_template" % /CONFIGFILE "%" /MAXCONCURRENT %'
				THEN REPLACE(REPLACE(REPLACE(STUFF(LEFT(command,CHARINDEX('/MAXCONCURRENT',command)-2),1,CHARINDEX('/CONFIGFILE',command)+12,''),'_','\_'),'[','\['),']','\]')
				ELSE '' END
			WHEN 'TSQL' THEN '在数据库 '+database_name+' 上执行：'+REPLACE(REPLACE(REPLACE(REPLACE(LEFT(command,100),NCHAR(13)+NCHAR(10),'  '),'_','\_'),'[','\['),']','\]')+CASE WHEN LEN(command)>100 THEN ' ...' ELSE '' END
		ELSE '' END+' |'
FROM msdb.dbo.sysjobsteps jst
WHERE jst.job_id = @JobID
ORDER BY step_id
FOR XML PATH('')),1,1,'')+'</s>'
SET @wiki = @wikixml.value('/s[1]','nvarchar(max)')
PRINT @wiki

PRINT '
h1. 执行计划
----
|| 日期 || 时间 ||'
SET @wikixml = '<s>'+
STUFF((
SELECT
	CHAR(10)+'| '+
	CASE
		WHEN s.freq_type = 4 THEN '每'+ISNULL(CAST(NULLIF(s.freq_interval,1) AS nvarchar(10)),'')+'天'
		WHEN s.freq_type = 8 THEN '每周'+
			CASE WHEN s.freq_interval & 1 > 0 THEN '0' ELSE '' END+
			CASE WHEN s.freq_interval & 2 > 0 THEN '1' ELSE '' END+
			CASE WHEN s.freq_interval & 4 > 0 THEN '2' ELSE '' END+
			CASE WHEN s.freq_interval & 8 > 0 THEN '3' ELSE '' END+
			CASE WHEN s.freq_interval & 16 > 0 THEN '4' ELSE '' END+
			CASE WHEN s.freq_interval & 32 > 0 THEN '5' ELSE '' END+
			CASE WHEN s.freq_interval & 64 > 0 THEN '6' ELSE '' END
		ELSE 'unknown' END+' | '+
	CASE
		WHEN s.freq_subday_type = 1 THEN STUFF(LEFT(RIGHT('00000'+CAST(s.active_start_time AS nvarchar(10)),6),4),3,0,':')
		ELSE CASE WHEN s.active_start_time = 0 AND s.active_end_time = 235959 THEN ''
			ELSE STUFF(LEFT(RIGHT('00000'+CAST(s.active_start_time AS nvarchar(10)),6),4),3,0,':')+'到'+STUFF(LEFT(RIGHT('00000'+CAST(s.active_end_time AS nvarchar(10)),6),4),3,0,':')+'期间'
			END+
			'每'+CAST(s.freq_subday_interval AS nvarchar(10))+CASE
			WHEN s.freq_subday_type = 2 THEN '秒'
			WHEN s.freq_subday_type = 4 THEN '分钟'
			WHEN s.freq_subday_type = 8 THEN '小时' END
		END+' |'
FROM msdb.dbo.sysjobschedules js
INNER JOIN msdb.dbo.sysschedules s
ON js.schedule_id = s.schedule_id
	AND s.enabled = 1
WHERE js.job_id = @JobID
ORDER BY s.freq_type,
	CASE WHEN s.freq_subday_type = 1 THEN 99 ELSE s.freq_subday_type END,
	CASE WHEN s.freq_subday_type = 1 THEN 0 ELSE s.freq_subday_interval END,
	s.active_start_time
FOR XML PATH('')),1,1,'')+'</s>'
SET @wiki = @wikixml.value('/s[1]','nvarchar(max)')
PRINT @wiki

PRINT '
h1. 部署服务器
----
'+REPLACE(@Server,'_','\_')

END

ELSE
BEGIN
	PRINT '找不到作业：'+@JobName
END

END
