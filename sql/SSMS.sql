--SSMS Query Shortcuts


--Ctrl+F1: Display top(100) of a table/view. Select "tablename,1000" then press Ctrl+F1 to display top(1000).
sp_executesql N'EXEC(N''SELECT TOP(''+@n+N'') * FROM ''+@tablename)',N'@tablename nvarchar(100),@n int=100',

--Ctrl+3: Display definition script of a view/SP/UDF.
sp_helptext
--Press Ctrl+T(Results to Text) first then Ctrl+3 will output good-formatted script, then press Ctrl+D switch back to (Results to Grid).
--Only use this for quick view. If modify, open script in Object Explorer. Because sp_helptext may break the script format sometimes.

--Ctrl+4: Display row count and used space of a table.
sp_spaceused
--For large table, this SP is faster than SELECT COUNT(*) FROM tablename.

--Ctrl+5: Display all indexes of a table.
sp_executesql N'SELECT i.name,i.index_id,i.type_desc,i.is_unique,i.is_disabled,keys=STUFF((SELECT '', ''+c.name FROM sys.index_columns ic INNER JOIN sys.columns c ON ic.object_id=c.object_id and ic.column_id=c.column_id WHERE ic.object_id=i.object_id and ic.index_id=i.index_id and ic.is_included_column=0 ORDER BY ic.key_ordinal FOR XML PATH('''')),1,2,''''),included_columns=STUFF((SELECT '', ''+c.name FROM sys.index_columns ic INNER JOIN sys.columns c ON ic.object_id=c.object_id and ic.column_id=c.column_id WHERE ic.object_id=i.object_id and ic.index_id=i.index_id and ic.is_included_column=1 ORDER BY ic.key_ordinal FOR XML PATH('''')),1,2,'''') FROM sys.indexes i WHERE i.object_id=OBJECT_ID(@tablename) ORDER BY 2;',N'@tablename nvarchar(100)',

--Ctrl+6: Display all triggers of a table.
sp_helptrigger

--Ctrl+7: Get columns of a table/view, in lines.
sp_executesql N'SELECT columns=name+'','' FROM sys.columns WHERE object_id=OBJECT_ID(@tablename) ORDER BY column_id',N'@tablename nvarchar(100)',

--Ctrl+8: Get columns of a table/view, separated by comma.
sp_executesql N'SELECT columns=STUFF((SELECT @sep+name FROM sys.columns WHERE object_id=OBJECT_ID(@tablename) FOR XML PATH('''')),1,DATALENGTH(@sep)/2,'''')',N'@tablename nvarchar(100),@sep nvarchar(5)='', ''',

--Ctrl+9: Search for view/SP/UDF which contains the keyword in script code.
sp_executesql N'SELECT o.type,o.type_desc,oname=schema_name(o.schema_id)+''.''+o.name,o.object_id FROM sys.objects o INNER JOIN sys.sql_modules sm ON o.object_id=sm.object_id WHERE sm.definition LIKE ''%''+@keyword+''%'' ESCAPE ''\'' ORDER BY type,oname',N'@keyword nvarchar(100)',

--Ctrl+0: Search for table/view/SP/UDF which contains keyword in name.
sp_executesql N'SELECT type,type_desc,oname=schema_name(schema_id)+''.''+name,object_id FROM sys.objects WHERE type IN (''P'',''FN'',''SN'',''TR'',''IF'',''TF'',''U'',''V'') AND name LIKE ''%''+REPLACE(@keyword,''_'',''\_'')+''%'' ESCAPE ''\'' ORDER BY type,oname',N'@keyword nvarchar(100)',

