/****************************************************************************
*              Confluence Wiki SQL������ҵ�ĵ����ɹ��� V1.1                 *
****************************************************************************/
SET NOCOUNT ON
GO
DECLARE @wikixml xml, @wiki nvarchar(max);
DECLARE @JobName nvarchar(200), @Server nvarchar(100);
/****************************************************************************
����������ҵ���б�
	SET @JobName = ''
������ҵ��Ϊ��XYZ����ҳ�棺
	SET @JobName = 'XYZ'
****************************************************************************/

SET @JobName = ''

SET @Server = '192.168.'




/****************************************************************************
���´��벻Ҫ����
****************************************************************************/
IF @JobName = ''
BEGIN
PRINT 'h1. ˵��
----
'+REPLACE(@Server,'_','\_')+' ��SQL������ҵ
��ʱ��˳���г�

h1. SQL������ҵ�б�
----
|| ���� || ʱ�� || ��ҵ�� ||'
SET @wikixml = '<s>'+
STUFF((
SELECT
	CHAR(10)+'| '+
	CASE
		WHEN s.freq_type = 4 THEN 'ÿ'+ISNULL(CAST(NULLIF(s.freq_interval,1) AS nvarchar(10)),'')+'��'
		WHEN s.freq_type = 8 THEN 'ÿ��'+
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
			ELSE STUFF(LEFT(RIGHT('00000'+CAST(s.active_start_time AS nvarchar(10)),6),4),3,0,':')+'��'+STUFF(LEFT(RIGHT('00000'+CAST(s.active_end_time AS nvarchar(10)),6),4),3,0,':')+'�ڼ�'
			END+
			'ÿ'+CAST(s.freq_subday_interval AS nvarchar(10))+CASE
			WHEN s.freq_subday_type = 2 THEN '��'
			WHEN s.freq_subday_type = 4 THEN '����'
			WHEN s.freq_subday_type = 8 THEN 'Сʱ' END
		END+' | ['+
	REPLACE(REPLACE(REPLACE(j.name,':','��'),'@','��'),'|','��')+'] |'
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
 
PRINT 'h1. ˵��
----
'+REPLACE(@JobDesc,'_','\_')+'
�����ˣ�

h1. ��ҵ����
----
|| ���� || ������ || ��� || �ɹ�ʱ || ʧ��ʱ || �����趨 || ���� ||'
SET @wikixml = '<s>'+
STUFF((
SELECT
	CHAR(10)+'| '+
	CAST(step_id AS nvarchar(10))+' | '+
	REPLACE(REPLACE(REPLACE(step_name,'_','\_'),'[','\['),']','\]')+' | '+
	subsystem+' | '+
	CASE on_success_action
		WHEN 1 THEN '�ɹ����˳�'
		WHEN 3 THEN 'ת����һ��'
		WHEN 4 THEN 'ת������'+CAST(on_success_step_id AS nvarchar(10))
		ELSE '' END+' | '+
	CASE on_fail_action
		WHEN 2 THEN 'ʧ�ܺ��˳�'
		WHEN 3 THEN 'ת����һ��'
		WHEN 4 THEN 'ת������'+CAST(on_fail_step_id AS nvarchar(10))
		ELSE '' END+' | '+
	CASE WHEN retry_attempts > 0 THEN '����'+CAST(retry_attempts AS nvarchar(10))+'�Σ����'+CAST(retry_interval AS nvarchar(10))+'����'
		ELSE '������' END+' | '+
	CASE subsystem
		WHEN 'SSIS' THEN
			CASE WHEN command LIKE '/SQL "\etl_framework_v2_5_main_template" % /CONFIGFILE "%" /MAXCONCURRENT %'
				THEN REPLACE(REPLACE(REPLACE(STUFF(LEFT(command,CHARINDEX('/MAXCONCURRENT',command)-2),1,CHARINDEX('/CONFIGFILE',command)+12,''),'_','\_'),'[','\['),']','\]')
				ELSE '' END
			WHEN 'TSQL' THEN '�����ݿ� '+database_name+' ��ִ�У�'+REPLACE(REPLACE(REPLACE(REPLACE(LEFT(command,100),NCHAR(13)+NCHAR(10),'  '),'_','\_'),'[','\['),']','\]')+CASE WHEN LEN(command)>100 THEN ' ...' ELSE '' END
		ELSE '' END+' |'
FROM msdb.dbo.sysjobsteps jst
WHERE jst.job_id = @JobID
ORDER BY step_id
FOR XML PATH('')),1,1,'')+'</s>'
SET @wiki = @wikixml.value('/s[1]','nvarchar(max)')
PRINT @wiki

PRINT '
h1. ִ�мƻ�
----
|| ���� || ʱ�� ||'
SET @wikixml = '<s>'+
STUFF((
SELECT
	CHAR(10)+'| '+
	CASE
		WHEN s.freq_type = 4 THEN 'ÿ'+ISNULL(CAST(NULLIF(s.freq_interval,1) AS nvarchar(10)),'')+'��'
		WHEN s.freq_type = 8 THEN 'ÿ��'+
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
			ELSE STUFF(LEFT(RIGHT('00000'+CAST(s.active_start_time AS nvarchar(10)),6),4),3,0,':')+'��'+STUFF(LEFT(RIGHT('00000'+CAST(s.active_end_time AS nvarchar(10)),6),4),3,0,':')+'�ڼ�'
			END+
			'ÿ'+CAST(s.freq_subday_interval AS nvarchar(10))+CASE
			WHEN s.freq_subday_type = 2 THEN '��'
			WHEN s.freq_subday_type = 4 THEN '����'
			WHEN s.freq_subday_type = 8 THEN 'Сʱ' END
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
h1. ���������
----
'+REPLACE(@Server,'_','\_')

END

ELSE
BEGIN
	PRINT '�Ҳ�����ҵ��'+@JobName
END

END
