--Ctrl+F1����ʾ�����ͼ��ǰ100�У�ѡ����tablename,1000����Ctrl+F1����ʾ���ǰ1000��
sp_executesql N'EXEC(N''SELECT TOP(''+@n+N'') * FROM ''+@tablename)',N'@tablename nvarchar(100),@n int=100',
--Ctrl+3����ʾ��ͼ���洢���̡��������������Ķ���ű�
sp_helptext
--Ctrl+4����ʾ���������ռ�ÿռ�
sp_spaceused
--Ctrl+5����ʾ�������
sp_helpindex
--Ctrl+6����ʾ��Ĵ�������Ϣ
sp_helptrigger
--Ctrl+8����ʾ�����ͼ���ֶ������Զ��ſո�ָ�
sp_executesql N'SELECT columns=STUFF((SELECT @sep+name FROM sys.columns WHERE object_id=OBJECT_ID(@tablename) FOR XML PATH('''')),1,DATALENGTH(@sep)/2,'''')',N'@tablename nvarchar(100),@sep nvarchar(5)='', ''',
--Ctrl+9����ʾ�ؼ��ʵ�������Ϣ
sp_executesql N'SELECT oname=OBJECT_NAME(object_id) FROM sys.sql_modules WHERE definition LIKE ''%''+@keyword+''%'' ORDER BY oname',N'@keyword nvarchar(100)',
--Ctrl+0������ѡ���ؼ����ڵ�ǰ���ݿ��в��ұ���ͼ���洢���̡�����
sp_executesql N'SELECT type,type_desc,oname=SCHEMA_NAME(schema_id)+''.''+name,object_id FROM sys.objects WHERE type IN (''P'',''FN'',''SN'',''TR'',''IF'',''TF'',''U'',''V'') AND name LIKE ''%''+@keyword+''%'' ORDER BY type,oname',N'@keyword nvarchar(100)',
