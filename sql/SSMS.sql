--Ctrl+F1����ʾ�����ͼ��ǰ100�У�ѡ����tablename,1000����Ctrl+F1����ʾ���ǰ1000��
sp_executesql N'EXEC(N''SELECT TOP(''+@n+N'') * FROM ''+@tablename)',N'@tablename nvarchar(100),@n int=100',
--Ctrl+3����ʾ��ͼ���洢���̡��������������Ķ���ű�
sp_helptext
--Ctrl+4����ʾ���������ռ�ÿռ�
sp_spaceused
--Ctrl+5����ʾ����ÿ������ռ�õĿռ�
sp_executesql N'SELECT index_name = ind.name, ddps.used_page_count, ddps.reserved_page_count, ddps.row_count FROM sys.indexes ind INNER JOIN sys.dm_db_partition_stats ddps ON ind.object_id = ddps.object_id AND ind.index_id = ddps.index_id WHERE ind.object_id = OBJECT_ID(@tablename)',N'@tablename nvarchar(100)',
--Ctrl+6����ʾ��Ĵ�������Ϣ
sp_helptrigger
--Ctrl+8����ʾ�����ͼ���ֶ������Զ��ſո�ָ�
sp_executesql N'SELECT columns = STUFF((SELECT @sep+name FROM sys.columns WHERE object_id = OBJECT_ID(@tablename) FOR XML PATH('''')),1,DATALENGTH(@sep)/2,'''')',N'@tablename nvarchar(100),@sep nvarchar(5)='', ''',
--Ctrl+9����ʾ�ؼ��ʵ�������Ϣ
sp_executesql N'SELECT oname=object_name(object_id) FROM sys.sql_modules WHERE definition LIKE ''%''+@keyword+''%'' ORDER BY oname',N'@keyword nvarchar(100)',
--Ctrl+0������ѡ���ؼ����ڵ�ǰ���ݿ��в��ұ���ͼ���洢���̡�����
sp_executesql N'SELECT * FROM sys.objects WHERE type IN (''P'',''FN'',''SN'',''TR'',''IF'',''TF'',''U'',''V'') AND name LIKE ''%''+@keyword+''%'' ORDER BY type,name',N'@keyword nvarchar(100)',
