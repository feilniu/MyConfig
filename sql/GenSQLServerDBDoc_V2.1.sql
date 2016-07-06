/****************************************************************************
*              Confluence Wiki 数据库文档生成工具 V2.1                      *
****************************************************************************/
SET NOCOUNT ON
GO
DECLARE @ObjectNames nvarchar(max)

/****************************************************************************
在此处指定需要生成文档的数据库对象，每行一个，格式为“schema_name.object_name”，忽略空行，如：
SET @ObjectNames = '
dbo.table_name
dbo.usp_name
'
****************************************************************************/

SET @ObjectNames = '




'

/****************************************************************************
以下代码不要更改
****************************************************************************/
DECLARE @wikixml xml, @wiki nvarchar(max);
DECLARE @ObjectID int, @ObjectName nvarchar(200), @ObjectDesc nvarchar(200), @ObjectDef nvarchar(max);

DECLARE @ObjectList TABLE(
	SN int IDENTITY(1,1) NOT NULL PRIMARY KEY CLUSTERED,
	ObjectID int NOT NULL UNIQUE,
	ObjectName nvarchar(200) NOT NULL UNIQUE,
	ObjectDesc nvarchar(200) NOT NULL,
	ObjectType char(2) NOT NULL)

DECLARE @eol nvarchar(10), @leol int
SET @eol = CHAR(13)+CHAR(10)
SET @leol = LEN(@eol)
DECLARE @i int, @Item nvarchar(500)
WHILE LEN(@ObjectNames) > 0
BEGIN
	SET @i = CHARINDEX(@eol,@ObjectNames)
	IF @i = 1
	BEGIN
		SET @ObjectNames = STUFF(@ObjectNames,1,@leol,'')
		CONTINUE
	END
	IF @i = 0
	BEGIN
		SET @Item = @ObjectNames
		SET @ObjectNames = ''
	END
	ELSE
	BEGIN
		SET @Item = LEFT(@ObjectNames,@i-1)
		SET @ObjectNames = STUFF(@ObjectNames,1,@i-1+@leol,'')
	END
	IF @Item LIKE '%.%'
	BEGIN
		INSERT INTO @ObjectList
		SELECT
			ObjectID = o.object_id,
			ObjectName = REPLACE(s.name,'_','\_')+'.'+REPLACE(o.name,'_','\_'),
			ObjectDesc = ISNULL(CAST(ep.value AS nvarchar(200)),''),
			ObjectType = o.type
		FROM sys.objects o
		INNER JOIN sys.schemas s
		ON o.schema_id = s.schema_id
		LEFT JOIN sys.extended_properties ep
		ON ep.major_id = o.object_id
			AND ep.minor_id = 0
			AND ep.name = 'MS_Description'
		WHERE o.type IN ('P','FN','IF','TF','U','V')
			AND o.name = PARSENAME(@Item,1)
			AND s.name = PARSENAME(@Item,2)
	END
END

SELECT * FROM @ObjectList ORDER BY ObjectType, SN

PRINT 'h1. 说明
----
{excerpt}摘要{excerpt}
其它说明

h1. 数据库对象列表
----
{toc:minLevel=2}
'

IF EXISTS (SELECT * FROM @ObjectList WHERE ObjectType = 'U')
BEGIN
PRINT '
h2. 表
----
'
DECLARE curTables CURSOR FOR
SELECT ObjectID, ObjectName, ObjectDesc
FROM @ObjectList
WHERE ObjectType = 'U'
ORDER BY SN
;
OPEN curTables
FETCH NEXT FROM curTables INTO @ObjectID, @ObjectName, @ObjectDesc
WHILE @@FETCH_STATUS = 0
BEGIN

PRINT '
h3. '+@ObjectName+' - '+@ObjectDesc+'
* 字段
|| 字段名 || 类型 || 可空 || 标识列 || 计算列 || 默认值 || 备注 ||'
SET @wikixml = '<s>'+
STUFF((
SELECT
	CHAR(10)+'| '+
	REPLACE(c.name,'_','\_')+' | '+
	ty.name+CASE
		WHEN c.user_type_id IN (165,167,173,175) THEN '('+ISNULL(CAST(NULLIF(c.max_length,-1) AS nvarchar(10)),'max')+')'
		WHEN c.user_type_id IN (231,239) THEN '('+ISNULL(CAST(NULLIF(c.max_length,-1)/2 AS nvarchar(10)),'max')+')'
		WHEN c.user_type_id IN (106,108) THEN '('+CAST(c.precision AS nvarchar(10))+','+CAST(c.scale AS nvarchar(10))+')'
		ELSE '' END+' | '+
	CASE WHEN c.is_nullable = 1 THEN '(/)' ELSE '' END+' | '+
	CASE WHEN c.is_identity = 1 THEN '('+CAST(id.seed_value AS nvarchar(10))+','+CAST(id.increment_value AS nvarchar(10))+')' ELSE '' END+' | '+
	CASE WHEN c.is_computed = 1 THEN '(/)' ELSE '' END+' | '+
	CASE WHEN c.default_object_id <> 0 THEN SUBSTRING(df.definition,2,LEN(df.definition)-2) ELSE '' END+' | '+
	ISNULL(CAST(ep.value AS nvarchar(200)),'')+' |'
FROM sys.columns c
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
LEFT JOIN sys.identity_columns id ON c.object_id = id.object_id AND c.column_id = id.column_id
--LEFT JOIN sys.computed_columns cc ON c.object_id = cc.object_id AND c.column_id = cc.column_id
LEFT JOIN sys.default_constraints df ON c.default_object_id = df.object_id
LEFT JOIN sys.extended_properties ep
ON ep.major_id = c.object_id
	AND ep.minor_id = c.column_id
	AND ep.name = 'MS_Description'
WHERE c.object_id = @ObjectID
ORDER BY c.column_id
FOR XML PATH('')),1,1,'')+'</s>'
SET @wiki = @wikixml.value('/s[1]','nvarchar(max)')
PRINT @wiki

PRINT '* 主键、唯一键和索引
|| 键类型 || 名称 || 字段 || 聚集 || 唯一 || 忽略重复 || 填充因子 ||'
SET @wikixml = '<s>'+
STUFF((
SELECT
	CHAR(10)+'| '+
	CASE WHEN i.is_primary_key = 1 THEN 'PK' WHEN i.is_unique_constraint = 1 THEN 'UQ' ELSE '' END+' | '+
	REPLACE(i.name,'_','\_')+' | '+
	STUFF((
	SELECT ','+REPLACE(c.name,'_','\_')+CASE WHEN ic.is_descending_key = 1 THEN ' DESC' ELSE '' END
	FROM sys.index_columns ic
	INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
	WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
		AND ic.is_included_column = 0
	ORDER BY ic.key_ordinal
	FOR XML PATH('')),1,1,'')+
	ISNULL(', {color:blue}INCLUDE{color}('+STUFF((
	SELECT ','+REPLACE(c.name,'_','\_')
	FROM sys.index_columns ic
	INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
	WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
		AND ic.is_included_column = 1
	ORDER BY ic.index_column_id
	FOR XML PATH('')),1,1,'')+')','')+' | '+
	CASE WHEN i.index_id = 1 THEN '(/)' ELSE '' END+' | '+
	CASE WHEN i.is_unique = 1 THEN '(/)' ELSE '' END+' | '+
	CASE WHEN i.ignore_dup_key = 1 THEN '(/)' ELSE '' END+' | '+
	CASE WHEN i.fill_factor > 0 THEN CAST(i.fill_factor AS nvarchar(10)) + '%' ELSE '' END+' |'
FROM sys.indexes i
WHERE i.object_id = @ObjectID
	AND i.index_id > 0
ORDER BY i.is_primary_key DESC, i.is_unique_constraint DESC, i.index_id
FOR XML PATH('')),1,1,'')+'</s>'
SET @wiki = @wikixml.value('/s[1]','nvarchar(max)')
PRINT @wiki

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE parent_object_id = @ObjectID)
BEGIN
PRINT '* 外键
|| 名称 || 字段 || 引用表 || 引用字段 || ON DELETE || ON UPDATE ||'
SET @wikixml = '<s>'+
STUFF((
SELECT
	CHAR(10)+'| '+
	REPLACE(fk.name,'_','\_')+' | '+
	STUFF((
	SELECT ','+REPLACE(c.name,'_','\_')
	FROM sys.foreign_key_columns fkc
	INNER JOIN sys.columns c ON fkc.parent_object_id = c.object_id AND fkc.parent_column_id = c.column_id
	WHERE fkc.constraint_object_id = fk.object_id
	ORDER BY fkc.constraint_column_id
	FOR XML PATH('')),1,1,'')+' | '+
	REPLACE(s.name,'_','\_')+'.'+REPLACE(o.name,'_','\_')+' | '+
	STUFF((
	SELECT ','+REPLACE(c.name,'_','\_')
	FROM sys.foreign_key_columns fkc
	INNER JOIN sys.columns c ON fkc.referenced_object_id = c.object_id AND fkc.referenced_column_id = c.column_id
	WHERE fkc.constraint_object_id = fk.object_id
	ORDER BY fkc.constraint_column_id
	FOR XML PATH('')),1,1,'')+' | '+
	fk.delete_referential_action_desc COLLATE Chinese_PRC_CI_AS+' | '+
	fk.update_referential_action_desc COLLATE Chinese_PRC_CI_AS+' |'
FROM sys.foreign_keys fk
INNER JOIN sys.objects o
ON fk.referenced_object_id = o.object_id
INNER JOIN sys.schemas s
ON o.schema_id = s.schema_id
WHERE fk.parent_object_id = @ObjectID
ORDER BY fk.name
FOR XML PATH('')),1,1,'')+'</s>'
SET @wiki = @wikixml.value('/s[1]','nvarchar(max)')
PRINT @wiki
END

IF EXISTS (SELECT * FROM sys.check_constraints WHERE parent_object_id = @ObjectID)
BEGIN
PRINT '* CHECK约束
|| 名称 || 表达式 ||'
SET @wikixml = '<s>'+
STUFF((
SELECT
	CHAR(10)+'| '+
	REPLACE(ck.name,'_','\_')+' | '+
	REPLACE(REPLACE(REPLACE(SUBSTRING(ck.definition,2,LEN(ck.definition)-2),'_','\_'),'[','\['),']','\]')+' |'
FROM sys.check_constraints ck
WHERE ck.parent_object_id = @ObjectID
ORDER BY ck.name
FOR XML PATH('')),1,1,'')+'</s>'
SET @wiki = @wikixml.value('/s[1]','nvarchar(max)')
PRINT @wiki
END

IF EXISTS (SELECT * FROM sys.triggers WHERE parent_id = @ObjectID)
BEGIN
PRINT '* 触发器
|| 名称 || INSTEAD OF || 备注 ||'
SET @wikixml = '<s>'+
STUFF((
SELECT
	CHAR(10)+'| '+
	REPLACE(tr.name,'_','\_')+' | '+
	CASE WHEN tr.is_instead_of_trigger = 1 THEN '(/)' ELSE '' END+' | '+
	ISNULL(CAST(ep.value AS nvarchar(200)),'')+' |'
FROM sys.triggers tr
LEFT JOIN sys.extended_properties ep
ON ep.major_id = tr.object_id
	AND ep.minor_id = 0
	AND ep.name = 'MS_Description'
WHERE tr.parent_id = @ObjectID
ORDER BY tr.name
FOR XML PATH('')),1,1,'')+'</s>'
SET @wiki = @wikixml.value('/s[1]','nvarchar(max)')
PRINT @wiki
END

	FETCH NEXT FROM curTables INTO @ObjectID, @ObjectName, @ObjectDesc
END
CLOSE curTables
DEALLOCATE curTables
END


IF EXISTS (SELECT * FROM @ObjectList WHERE ObjectType = 'V')
BEGIN
PRINT '
h2. 视图
----
'
DECLARE curViews CURSOR FOR
SELECT ObjectID, ObjectName, ObjectDesc
FROM @ObjectList
WHERE ObjectType = 'V'
ORDER BY SN
;
OPEN curViews
FETCH NEXT FROM curViews INTO @ObjectID, @ObjectName, @ObjectDesc
WHILE @@FETCH_STATUS = 0
BEGIN

PRINT '
h3. '+@ObjectName+' - '+@ObjectDesc
SET @ObjectDef = (SELECT definition FROM sys.sql_modules WHERE object_id = @ObjectID)
IF LEN(@ObjectDef) < 3000
BEGIN
SET @wiki = '{code:lang=sql}
'+@ObjectDef+'{code}'
PRINT @wiki
END

	FETCH NEXT FROM curViews INTO @ObjectID, @ObjectName, @ObjectDesc
END
CLOSE curViews
DEALLOCATE curViews
END


IF EXISTS (SELECT * FROM @ObjectList WHERE ObjectType = 'P')
BEGIN
PRINT '
h2. 存储过程
----
'
DECLARE @iStart int, @iEnd int;
DECLARE curSPs CURSOR FOR
SELECT ObjectID, ObjectName, ObjectDesc
FROM @ObjectList
WHERE ObjectType = 'P'
ORDER BY SN
;
OPEN curSPs
FETCH NEXT FROM curSPs INTO @ObjectID, @ObjectName, @ObjectDesc
WHILE @@FETCH_STATUS = 0
BEGIN

PRINT '
h3. '+@ObjectName+' - '+@ObjectDesc
SET @ObjectDef = (SELECT definition FROM sys.sql_modules WHERE object_id = @ObjectID)
SET @iStart = PATINDEX('%[(@]%',@ObjectDef)
SET @iEnd = PATINDEX('%[^0-9A-Z_]AS[^0-9A-Z_]%',@ObjectDef)
IF @iStart > 0 AND @iStart < @iEnd
BEGIN
SET @ObjectDef = SUBSTRING(@ObjectDef,@iStart,@iEnd-@iStart+1)
IF LEN(@ObjectDef) BETWEEN 6 AND 3000
BEGIN
SET @wiki = '* 参数定义
{code:lang=sql}
'+@ObjectDef+'{code}'
PRINT @wiki
END
END

	FETCH NEXT FROM curSPs INTO @ObjectID, @ObjectName, @ObjectDesc
END
CLOSE curSPs
DEALLOCATE curSPs
END


IF EXISTS (SELECT * FROM @ObjectList WHERE ObjectType = 'FN')
BEGIN
PRINT '
h2. 标量函数
----
'
DECLARE curFNs CURSOR FOR
SELECT ObjectID, ObjectName, ObjectDesc
FROM @ObjectList
WHERE ObjectType = 'FN'
ORDER BY SN
;
OPEN curFNs
FETCH NEXT FROM curFNs INTO @ObjectID, @ObjectName, @ObjectDesc
WHILE @@FETCH_STATUS = 0
BEGIN

PRINT '
h3. '+@ObjectName+' - '+@ObjectDesc
SET @ObjectDef = (SELECT definition FROM sys.sql_modules WHERE object_id = @ObjectID)
IF LEN(@ObjectDef) < 3000
BEGIN
SET @wiki = '{code:lang=sql}
'+@ObjectDef+'{code}'
PRINT @wiki
END

	FETCH NEXT FROM curFNs INTO @ObjectID, @ObjectName, @ObjectDesc
END
CLOSE curFNs
DEALLOCATE curFNs
END


IF EXISTS (SELECT * FROM @ObjectList WHERE ObjectType IN ('TF','IF'))
BEGIN
PRINT '
h2. 表值函数
----
'
DECLARE curTFs CURSOR FOR
SELECT ObjectID, ObjectName, ObjectDesc
FROM @ObjectList
WHERE ObjectType IN ('TF','IF')
ORDER BY SN
;
OPEN curTFs
FETCH NEXT FROM curTFs INTO @ObjectID, @ObjectName, @ObjectDesc
WHILE @@FETCH_STATUS = 0
BEGIN

PRINT '
h3. '+@ObjectName+' - '+@ObjectDesc
SET @ObjectDef = (SELECT definition FROM sys.sql_modules WHERE object_id = @ObjectID)
IF LEN(@ObjectDef) < 3000
BEGIN
SET @wiki = '{code:lang=sql}
'+@ObjectDef+'{code}'
PRINT @wiki
END

	FETCH NEXT FROM curTFs INTO @ObjectID, @ObjectName, @ObjectDesc
END
CLOSE curTFs
DEALLOCATE curTFs
END
