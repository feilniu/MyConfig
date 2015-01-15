--Ctrl+F1：显示表或视图的前100行，选定“tablename,1000”按Ctrl+F1可显示表的前1000行
sp_executesql N'EXEC(N''SELECT TOP(''+@n+N'') * FROM ''+@tablename)',N'@tablename nvarchar(100),@n int=100',
--Ctrl+3：显示视图、存储过程、函数、触发器的定义脚本
sp_helptext
--Ctrl+4：显示表的行数和占用空间
sp_spaceused
--Ctrl+5：显示表的索引
sp_helpindex
--Ctrl+6：显示表的触发器信息
sp_helptrigger
--Ctrl+8：显示表或视图的字段名，以逗号空格分隔
sp_executesql N'SELECT columns=STUFF((SELECT @sep+name FROM sys.columns WHERE object_id=OBJECT_ID(@tablename) FOR XML PATH('''')),1,DATALENGTH(@sep)/2,'''')',N'@tablename nvarchar(100),@sep nvarchar(5)='', ''',
--Ctrl+9：显示关键词的引用信息
sp_executesql N'SELECT oname=OBJECT_NAME(object_id) FROM sys.sql_modules WHERE definition LIKE ''%''+@keyword+''%'' ORDER BY oname',N'@keyword nvarchar(100)',
--Ctrl+0：根据选定关键词在当前数据库中查找表、视图、存储过程、函数
sp_executesql N'SELECT type,type_desc,oname=SCHEMA_NAME(schema_id)+''.''+name,object_id FROM sys.objects WHERE type IN (''P'',''FN'',''SN'',''TR'',''IF'',''TF'',''U'',''V'') AND name LIKE ''%''+@keyword+''%'' ORDER BY type,oname',N'@keyword nvarchar(100)',
