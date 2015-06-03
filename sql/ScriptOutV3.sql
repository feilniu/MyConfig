SET QUOTED_IDENTIFIER ON;
DECLARE @eol nvarchar(10), @leol int;
SET @eol = CHAR(13)+CHAR(10);
SET @leol = LEN(@eol);
DECLARE @sql nvarchar(max), @len int, @oname nvarchar(200), @oid int, @otype char(2);
DECLARE @uses_ansi_nulls bit, @uses_quoted_identifier bit;
SET @oname = '$(object_name)';
SET @oid = OBJECT_ID(@oname);
SET @otype = (SELECT type FROM sys.objects WHERE object_id = @oid);

IF @otype = 'U'
BEGIN
	DECLARE @sqlxml xml;

	SELECT @uses_ansi_nulls = uses_ansi_nulls FROM sys.tables WHERE object_id = @oid;
	SET @sql = 'SET ANSI_NULLS ' + CASE WHEN @uses_ansi_nulls = 1 THEN 'ON' ELSE 'OFF' END + @eol + 'GO' + @eol
		+ 'SET QUOTED_IDENTIFIER ON' + @eol + 'GO' + @eol
		+ 'SET ANSI_PADDING ON' + @eol + 'GO' + @eol
		+ 'CREATE TABLE '+@oname+'(';

	SET @sqlxml = '<s>'+
	STUFF((
	SELECT
		','+@eol+CHAR(9)+
		c.name+
		' '+CASE WHEN c.is_computed = 1 THEN 'AS '+cc.definition+CASE WHEN cc.is_persisted = 1 THEN ' PERSISTED' ELSE '' END
			ELSE
				ty.name+CASE
					WHEN c.user_type_id IN (165,167,173,175) THEN '('+ISNULL(CAST(NULLIF(c.max_length,-1) AS nvarchar(10)),'max')+')'
					WHEN c.user_type_id IN (231,239) THEN '('+ISNULL(CAST(NULLIF(c.max_length,-1)/2 AS nvarchar(10)),'max')+')'
					WHEN c.user_type_id IN (106,108) THEN '('+CAST(c.precision AS nvarchar(10))+','+CAST(c.scale AS nvarchar(10))+')'
					ELSE '' END+
				CASE WHEN c.is_identity = 1 THEN ' IDENTITY('+CAST(id.seed_value AS nvarchar(10))+','+CAST(id.increment_value AS nvarchar(10))+')' ELSE '' END+
				' '+CASE WHEN c.is_nullable = 1 THEN 'NULL' ELSE 'NOT NULL' END+
				CASE WHEN c.default_object_id <> 0 THEN ' DEFAULT'+df.definition ELSE '' END
			END
	FROM sys.columns c
	INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
	LEFT JOIN sys.identity_columns id ON c.object_id = id.object_id AND c.column_id = id.column_id
	LEFT JOIN sys.computed_columns cc ON c.object_id = cc.object_id AND c.column_id = cc.column_id
	LEFT JOIN sys.default_constraints df ON c.default_object_id = df.object_id
	WHERE c.object_id = @oid
	ORDER BY c.column_id
	FOR XML PATH('')),1,1,'')+'</s>';
	SET @sql = @sql + @sqlxml.value('/s[1]','nvarchar(max)');

	SET @sqlxml = '<s>'+
	ISNULL((
	SELECT
		','+@eol+CHAR(9)+'CONSTRAINT '+
		kc.name+
		' '+CASE WHEN kc.type = 'PK' THEN 'PRIMARY KEY'
			ELSE 'UNIQUE' END+
		CASE WHEN i.index_id = 1 THEN ' CLUSTERED' ELSE '' END+
		'('+
		STUFF((
		SELECT ','+c.name+CASE WHEN ic.is_descending_key = 1 THEN ' DESC' ELSE '' END
		FROM sys.index_columns ic
		INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
		WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
			AND ic.is_included_column = 0
		ORDER BY ic.key_ordinal
		FOR XML PATH('')),1,1,'')+')'+
		ISNULL(' WITH ('+STUFF(NULLIF(
		ISNULL(', '+CASE WHEN i.fill_factor > 0 THEN 'FILLFACTOR = '+CAST(i.fill_factor AS nvarchar(10)) END,'')+
		ISNULL(', '+CASE WHEN i.is_padded = 1 THEN 'PAD_INDEX = ON' END,'')+
		ISNULL(', '+CASE WHEN i.ignore_dup_key = 1 THEN 'IGNORE_DUP_KEY = ON' END,''),''),1,2,'')+')','')
	FROM sys.key_constraints kc
	INNER JOIN sys.indexes i
	ON kc.parent_object_id = i.object_id
		AND kc.unique_index_id = i.index_id
	WHERE kc.parent_object_id = @oid
	ORDER BY kc.type, i.index_id
	FOR XML PATH('')),'')+'</s>';
	SET @sql = @sql + @sqlxml.value('/s[1]','nvarchar(max)');

	SET @sqlxml = '<s>'+
	ISNULL((
	SELECT
		','+@eol+CHAR(9)+'CONSTRAINT '+
		fk.name+
		' FOREIGN KEY('+
		STUFF((
		SELECT ','+c.name
		FROM sys.foreign_key_columns fkc
		INNER JOIN sys.columns c ON fkc.parent_object_id = c.object_id AND fkc.parent_column_id = c.column_id
		WHERE fkc.constraint_object_id = fk.object_id
		ORDER BY fkc.constraint_column_id
		FOR XML PATH('')),1,1,'')+') REFERENCES '+
		s.name+'.'+o.name+'('+
		STUFF((
		SELECT ','+c.name
		FROM sys.foreign_key_columns fkc
		INNER JOIN sys.columns c ON fkc.referenced_object_id = c.object_id AND fkc.referenced_column_id = c.column_id
		WHERE fkc.constraint_object_id = fk.object_id
		ORDER BY fkc.constraint_column_id
		FOR XML PATH('')),1,1,'')+')'+
		CASE WHEN fk.delete_referential_action > 0 THEN
			@eol+CHAR(9)+CHAR(9)+'ON DELETE '+fk.delete_referential_action_desc COLLATE Chinese_PRC_CI_AS
		ELSE '' END+
		CASE WHEN fk.update_referential_action > 0 THEN
			@eol+CHAR(9)+CHAR(9)+'ON UPDATE '+fk.update_referential_action_desc COLLATE Chinese_PRC_CI_AS
		ELSE '' END
	FROM sys.foreign_keys fk
	INNER JOIN sys.objects o
	ON fk.referenced_object_id = o.object_id
	INNER JOIN sys.schemas s
	ON o.schema_id = s.schema_id
	WHERE fk.parent_object_id = @oid
	ORDER BY fk.name
	FOR XML PATH('')),'')+'</s>';
	SET @sql = @sql + @sqlxml.value('/s[1]','nvarchar(max)');

	SET @sqlxml = '<s>'+
	ISNULL((
	SELECT ','+@eol+CHAR(9)+'CONSTRAINT '+ck.name+' CHECK'+ck.definition
	FROM sys.check_constraints ck
	WHERE ck.parent_object_id = @oid
	ORDER BY ck.name
	FOR XML PATH('')),'')+'</s>';
	SET @sql = @sql + @sqlxml.value('/s[1]','nvarchar(max)');

	SET @sql = @sql + @eol + ');' + @eol + 'GO';

	SET @sqlxml = '<s>'+ (
	SELECT
		@eol+'CREATE'+
		CASE WHEN i.is_unique = 1 THEN ' UNIQUE' ELSE '' END+
		CASE WHEN i.index_id = 1 THEN ' CLUSTERED' ELSE '' END+
		' INDEX '+
		i.name+' ON '+@oname+'('+
		STUFF((
		SELECT ','+c.name+CASE WHEN ic.is_descending_key = 1 THEN ' DESC' ELSE '' END
		FROM sys.index_columns ic
		INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
		WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
			AND ic.is_included_column = 0
		ORDER BY ic.key_ordinal
		FOR XML PATH('')),1,1,'')+')'+
		ISNULL(' INCLUDE('+STUFF((
		SELECT ','+c.name
		FROM sys.index_columns ic
		INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
		WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
			AND ic.is_included_column = 1
		ORDER BY ic.index_column_id
		FOR XML PATH('')),1,1,'')+')','')+
		CASE WHEN i.has_filter = 1 THEN ' WHERE '+i.filter_definition ELSE '' END+
		ISNULL(' WITH ('+STUFF(NULLIF(
		ISNULL(', '+CASE WHEN i.fill_factor > 0 THEN 'FILLFACTOR = '+CAST(i.fill_factor AS nvarchar(10)) END,'')+
		ISNULL(', '+CASE WHEN i.is_padded = 1 THEN 'PAD_INDEX = ON' END,'')+
		ISNULL(', '+CASE WHEN i.ignore_dup_key = 1 THEN 'IGNORE_DUP_KEY = ON' END,''),''),1,2,'')+')','')
		+';'
	FROM sys.indexes i
	WHERE i.object_id = @oid
		AND i.is_primary_key = 0 AND i.is_unique_constraint = 0
		AND i.is_disabled = 0
	ORDER BY i.index_id
	FOR XML PATH(''))+'</s>';
	SET @sql = @sql + ISNULL(@sqlxml.value('/s[1]','nvarchar(max)'),'') + @eol + 'GO';

	IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = @oid AND data_space_id > 1)
		SET @sql = @sql + @eol + '--This table has index(es) created on partition_scheme or other filegroup.';
END
ELSE
BEGIN
	SELECT @sql = definition, @uses_ansi_nulls = uses_ansi_nulls, @uses_quoted_identifier = uses_quoted_identifier
	FROM sys.sql_modules
	WHERE object_id = @oid;

	SET @sql = 'SET ANSI_NULLS ' + CASE WHEN @uses_ansi_nulls = 1 THEN 'ON' ELSE 'OFF' END + @eol + 'GO' + @eol
		+ 'SET QUOTED_IDENTIFIER ' + CASE WHEN @uses_quoted_identifier = 1 THEN 'ON' ELSE 'OFF' END + @eol + 'GO' + @eol
		+ @sql;

	IF RIGHT(@sql,@leol) <> @eol SET @sql = @sql + @eol;

	SET @sql = @sql + 'GO';
END

IF @sql IS NOT NULL
BEGIN
	SET @len = LEN(@sql) + 1;
	IF @len <= 4000
	BEGIN
		PRINT @sql;
	END
	ELSE
	BEGIN
		DECLARE @tmp nvarchar(4000);
		DECLARE @lnb int,@lne int;
		SET @lnb = 1;
		SET @tmp = '';
		WHILE @lnb < @len
		BEGIN
			SET @lne = ISNULL(NULLIF(CHARINDEX(@eol,@sql,@lnb),0),@len);
			IF @lnb = @lne
			BEGIN
				SET @tmp = @tmp + @eol;
			END
			ELSE
			BEGIN
				SET @tmp = @tmp + SUBSTRING(@sql,@lnb,@lne-@lnb);
				PRINT @tmp;
				SET @tmp = '';
			END
			SET @lnb = @lne + @leol;
		END
	END
END
