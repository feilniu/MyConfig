--Ctrl+F1：显示表或视图的前100行，选定“tablename,1000”按Ctrl+F1可显示表的前1000行
sp_executesql N'EXEC(N''SELECT TOP(''+@n+N'') * FROM ''+@tablename)',N'@tablename nvarchar(100),@n int=100',
--Ctrl+3：显示视图、存储过程、函数、触发器的定义脚本
sp_helptext
--Ctrl+4：显示表的行数和占用空间
sp_spaceused
--Ctrl+5：显示表中每个索引占用的空间
sp_executesql N'SELECT index_name = ind.name, ddps.used_page_count, ddps.reserved_page_count, ddps.row_count FROM sys.indexes ind INNER JOIN sys.dm_db_partition_stats ddps ON ind.object_id = ddps.object_id AND ind.index_id = ddps.index_id WHERE ind.object_id = OBJECT_ID(@tablename)',N'@tablename nvarchar(100)',
--Ctrl+6：显示表的触发器信息
sp_helptrigger
--Ctrl+8：显示表或视图的字段名，以逗号空格分隔
sp_executesql N'SELECT columns = STUFF((SELECT @sep+name FROM sys.columns WHERE object_id = OBJECT_ID(@tablename) FOR XML PATH('''')),1,DATALENGTH(@sep)/2,'''')',N'@tablename nvarchar(100),@sep nvarchar(5)='', ''',
--Ctrl+9：显示关键词的引用信息
sp_executesql N'SELECT oname=object_name(object_id) FROM sys.sql_modules WHERE definition LIKE ''%''+@keyword+''%'' ORDER BY oname',N'@keyword nvarchar(100)',
--Ctrl+0：根据选定关键词在当前数据库中查找表、视图、存储过程、函数
sp_executesql N'SELECT * FROM sys.objects WHERE type IN (''P'',''FN'',''SN'',''TR'',''IF'',''TF'',''U'',''V'') AND name LIKE ''%''+@keyword+''%'' ORDER BY type,name',N'@keyword nvarchar(100)',
