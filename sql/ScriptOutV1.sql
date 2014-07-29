SET QUOTED_IDENTIFIER ON
DECLARE @eol nvarchar(10), @leol int
SET @eol = CHAR(13)+CHAR(10)
SET @leol = LEN(@eol)
DECLARE @sql nvarchar(max), @len int
SELECT @sql = definition
FROM sys.sql_modules
WHERE object_id = object_id('$(object_name)')
IF RIGHT(@sql,@leol) <> @eol SET @sql = @sql + @eol
SET @sql = @sql + 'GO'
IF @sql IS NOT NULL
BEGIN
	SET @len = LEN(@sql) + 1
	IF @len <= 4000
	BEGIN
		PRINT @sql
	END
	ELSE
	BEGIN
		DECLARE @tmp nvarchar(4000)
		DECLARE @lnb int,@lne int
		SET @lnb = 1
		SET @tmp = ''
		WHILE @lnb < @len
		BEGIN
			SET @lne = ISNULL(NULLIF(CHARINDEX(@eol,@sql,@lnb),0),@len)
			IF @lnb = @lne
			BEGIN
				SET @tmp = @tmp + @eol
			END
			ELSE
			BEGIN
				SET @tmp = @tmp + SUBSTRING(@sql,@lnb,@lne-@lnb)
				PRINT @tmp
				SET @tmp = ''
			END
			SET @lnb = @lne + @leol
		END
	END
END
