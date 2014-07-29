USE CommonDB
GO
--1.表
GO
--自然数表
GO
CREATE TABLE dbo.Nums(n int NOT NULL PRIMARY KEY CLUSTERED);
WITH B1 AS(SELECT n=1 UNION ALL SELECT n=1), --2
B2 AS(SELECT n=1 FROM B1 a CROSS JOIN B1 b), --4
B3 AS(SELECT n=1 FROM B2 a CROSS JOIN B2 b), --16
B4 AS(SELECT n=1 FROM B3 a CROSS JOIN B3 b), --256
B5 AS(SELECT n=1 FROM B4 a CROSS JOIN B4 b), --65536
CTE AS(SELECT r=ROW_NUMBER() OVER(ORDER BY (SELECT 1)) FROM B5 a CROSS JOIN B3 b) --65536 * 16
INSERT INTO dbo.Nums(n)
SELECT TOP(1000000) r FROM CTE ORDER BY r
GO
--日历表
GO
CREATE TABLE dbo.Calendar(
	Date datetime NOT NULL PRIMARY KEY CLUSTERED,
	DateStr AS CONVERT(char(8),Date,112),
	WeekDayDesc AS DATENAME(weekday,Date),
	IsWorkday bit NOT NULL,
	IsOpenday bit NOT NULL)
;
WITH CTE1 AS(
	SELECT
		Date = DATEADD(day,n,'19991231')
	FROM dbo.Nums
	WHERE n <= DATEDIFF(day,'19991231','20991231')),
CTE2 AS(
	SELECT
		Date,
		WeekDayKey = (DATEPART(weekday,Date) + @@DATEFIRST - 1) % 7
	FROM CTE1)
INSERT INTO dbo.Calendar
SELECT
	Date,
	IsWorkday = CASE WHEN WeekDayKey IN (0,6) THEN 0 ELSE 1 END,
	IsOpenday = CASE WHEN WeekDayKey IN (0,6) THEN 0 ELSE 1 END
FROM CTE2
;
GO
--2.函数
GO
--IP格式转换
GO
CREATE FUNCTION dbo.strIP2binIP(
@strIP varchar(15)
)
RETURNS binary(4)
AS
BEGIN
	RETURN CAST(CAST(PARSENAME(@strIP,4) AS int) AS binary(1)) +
		CAST(CAST(PARSENAME(@strIP,3) AS int) AS binary(1)) +
		CAST(CAST(PARSENAME(@strIP,2) AS int) AS binary(1)) +
		CAST(CAST(PARSENAME(@strIP,1) AS int) AS binary(1))
END
GO
CREATE FUNCTION dbo.binIP2strIP(
@binIP binary(4)
)
RETURNS varchar(15)
AS
BEGIN
	RETURN CAST(CAST(SUBSTRING(@binIP,1,1) AS int) AS varchar(3)) + '.' +
		CAST(CAST(SUBSTRING(@binIP,2,1) AS int) AS varchar(3)) + '.' +
		CAST(CAST(SUBSTRING(@binIP,3,1) AS int) AS varchar(3)) + '.' +
		CAST(CAST(SUBSTRING(@binIP,4,1) AS int) AS varchar(3))
END
GO
--中文全半角转换
GO
CREATE FUNCTION dbo.full2half(
@String nvarchar(max)
)
RETURNS nvarchar(max)
AS
/*
全角(Fullwidth)转换为半角(Halfwidth)
*/
BEGIN
	DECLARE @chr nchar(1)
	DECLARE @i int
	SET @String = REPLACE(@String,N'　',N' ')
	SET @i = PATINDEX(N'%[！-～]%' COLLATE Latin1_General_BIN,@String)
	WHILE @i > 0
	BEGIN
		SET @chr = SUBSTRING(@String,@i,1)
		SET @String = REPLACE(@String,@chr,NCHAR(UNICODE(@chr)-65248))
		SET @i = PATINDEX(N'%[！-～]%' COLLATE Latin1_General_BIN,@String)
	END
	RETURN @String
END
GO
CREATE FUNCTION dbo.half2full(
@String nvarchar(max)
)
RETURNS nvarchar(max)
AS
/*
半角(Halfwidth)转换为全角(Fullwidth)
*/
BEGIN
	DECLARE @chr nchar(1)
	DECLARE @i int
	SET @String = REPLACE(@String,N' ',N'　')
	SET @i = PATINDEX(N'%[!-~]%' COLLATE Latin1_General_BIN,@String)
	WHILE @i > 0
	BEGIN
		SET @chr = SUBSTRING(@String,@i,1)
		SET @String = REPLACE(@String,@chr,NCHAR(UNICODE(@chr)+65248))
		SET @i = PATINDEX(N'%[!-~]%' COLLATE Latin1_General_BIN,@String)
	END
	RETURN @String
END
GO
--GUID与字符串类型互转
GO
CREATE FUNCTION dbo.guid2str(
@guid uniqueidentifier
)
RETURNS char(32)
AS
BEGIN
	RETURN REPLACE(@guid,'-','')
END
GO
CREATE FUNCTION dbo.str2guid(
@str char(32)
)
RETURNS uniqueidentifier
AS
BEGIN
	RETURN CAST(LEFT(@str,8)+'-'+SUBSTRING(@str,9,4)+'-'+SUBSTRING(@str,13,4)+'-'+SUBSTRING(@str,17,4)+'-'+RIGHT(@str,12) AS uniqueidentifier)
END
GO
--格式化显示日期范围
GO
CREATE FUNCTION dbo.FormatDateRange(
@BDate datetime,
@EDate datetime
)
RETURNS varchar(30)
AS
BEGIN
	RETURN CONVERT(char(10),@BDate,111) + ISNULL(' - ' + CONVERT(char(10),NULLIF(@EDate,@BDate),111),'')
END
GO
--格式化显示秒数
GO
CREATE FUNCTION dbo.FormatSecondsAsHHMMSS(
@seconds int
)
RETURNS varchar(20)
BEGIN
	DECLARE @hh varchar(10), @mm varchar(10), @ss varchar(10)
	SET @hh = CAST(@seconds / 3600 AS varchar(10))
	IF LEN(@hh) = 1 SET @hh = '0' + @hh
	SET @seconds = @seconds % 3600
	SET @mm = RIGHT('00' + CAST(@seconds / 60 AS varchar(10)), 2)
	SET @ss = RIGHT('00' + CAST(@seconds % 60 AS varchar(10)), 2)
	RETURN @hh + ':' + @mm + ':' + @ss
END
GO
--拆分字符串
GO
CREATE FUNCTION dbo.Split(
@string varchar(max),
@separator varchar(10) = ','
)
RETURNS TABLE
AS
RETURN
	SELECT
		i = ROW_NUMBER() OVER(ORDER BY n),
		v = SUBSTRING(s, n, CHARINDEX(@separator, s + @separator, n) - n)
	FROM (SELECT s = @string) D
	JOIN dbo.Nums
	ON n <= LEN(s)
		AND SUBSTRING(@separator + s, n, LEN(@separator)) = @separator
GO
CREATE FUNCTION dbo.hexstr2varbin(
@hexstr varchar(max)
)
RETURNS varbinary(max)
AS
/*
将表示16进制的字符串转换为2进制类型
--TESTCASES
SELECT dbo.hexstr2varbin(NULL),NULL
SELECT dbo.hexstr2varbin(''),0x
SELECT dbo.hexstr2varbin('0x'),0x
SELECT dbo.hexstr2varbin('30394161'),0x30394161
SELECT dbo.hexstr2varbin('0x30394161'),0x30394161
SELECT dbo.hexstr2varbin('0x1A2B3C4D5E6F'),0x1A2B3C4D5E6F
SELECT dbo.hexstr2varbin('0x1a2b3c4d5e6f'),0x1a2b3c4d5e6f
--UNIMPLEMENTED
SELECT dbo.hexstr2varbin('0x3039416'),0x3039416
*/
BEGIN
	DECLARE @value int
	DECLARE @ascii int
	DECLARE @varbin varbinary(max)
	IF @hexstr LIKE '0x%'
		SET @hexstr = STUFF(@hexstr,1,2,'')
	SET @hexstr = UPPER(@hexstr)
	IF @hexstr NOT LIKE '%[^0-9A-F]%' COLLATE Chinese_PRC_BIN
	BEGIN
		SET @varbin = 0x
		WHILE @hexstr <> ''
		BEGIN
			SET @value = ASCII(SUBSTRING(@hexstr,1,1))
			IF @value <= 57
				SET @value = @value - 48
			ELSE
				SET @value = @value - 55
			SET @ascii = @value * 16
			SET @value = ASCII(SUBSTRING(@hexstr,2,1))
			IF @value <= 57
				SET @value = @value - 48
			ELSE
				SET @value = @value - 55
			SET @ascii = @ascii + @value
			SET @varbin = @varbin + CAST(@ascii AS binary(1))
			SET @hexstr = STUFF(@hexstr,1,2,'')
		END
	END
	RETURN @varbin
END
GO
CREATE FUNCTION dbo.varbin2hexstr(
@varbin varbinary(max)
)
RETURNS varchar(max)
AS
/*
将表示16进制的字符串转换为2进制类型
*/
BEGIN
	RETURN sys.fn_varbintohexsubstring(1,@varbin,1,0)
END
GO
CREATE TABLE dbo.StatPeriod(
	ID int NOT NULL,
	StatPeriod varchar(2) NOT NULL,
	StatPeriodDesc nvarchar(20) NOT NULL,
	CONSTRAINT PK_StatPeriod PRIMARY KEY CLUSTERED(ID),
	CONSTRAINT UQ_StatPeriod UNIQUE(StatPeriod)
)
GO
INSERT INTO dbo.StatPeriod(ID, StatPeriod, StatPeriodDesc)
SELECT 10, 'd', '天'
UNION ALL SELECT 20, 'w', '周'
UNION ALL SELECT 21, 'w1', '周（从周一开始）'
UNION ALL SELECT 22, 'w2', '周（从周二开始）'
UNION ALL SELECT 23, 'w3', '周（从周三开始）'
UNION ALL SELECT 24, 'w4', '周（从周四开始）'
UNION ALL SELECT 25, 'w5', '周（从周五开始）'
UNION ALL SELECT 26, 'w6', '周（从周六开始）'
UNION ALL SELECT 27, 'w7', '周（从周日开始）'
UNION ALL SELECT 30, 'm', '月'
UNION ALL SELECT 40, 'q', '季度'
UNION ALL SELECT 50, 'h', '半年'
UNION ALL SELECT 60, 'y', '年'
GO
CREATE FUNCTION dbo.PeriodCode(
@StatDate datetime,
@StatPeriod varchar(2) --SELECT * FROM dbo.StatPeriod
)
RETURNS varchar(10)
AS
BEGIN
	IF NOT (@StatPeriod LIKE '[dwmqhy]' OR @StatPeriod LIKE 'w[1-7]') RETURN NULL
	IF @StatPeriod = 'w' SET @StatPeriod = 'w7'
	RETURN @StatPeriod +
		CASE LEFT(@StatPeriod,1)
			WHEN 'd' THEN CONVERT(char(8),@StatDate,112)
			WHEN 'w' THEN CAST(DATEDIFF(week,'19000101',@StatDate-CAST(RIGHT(@StatPeriod,1) AS int)) AS varchar(10))
			WHEN 'm' THEN CONVERT(char(6),@StatDate,112)
			WHEN 'q' THEN CAST(YEAR(@StatDate) AS varchar(10))+CAST(DATEPART(quarter,@StatDate) AS varchar(10))
			WHEN 'h' THEN CAST(YEAR(@StatDate) AS varchar(10))+CAST(MONTH(@StatDate)/7+1 AS varchar(10))
			WHEN 'y' THEN CAST(YEAR(@StatDate) AS varchar(10))
		END
END
GO
CREATE FUNCTION dbo.PeriodDate(
@PeriodCode varchar(10)
)
RETURNS @PeriodDate TABLE(BTime datetime, ETime datetime)
AS
BEGIN
	DECLARE @BTime datetime, @ETime datetime
	IF @PeriodCode LIKE 'd[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
	BEGIN
		SET @BTime = CAST(SUBSTRING(@PeriodCode,2,8) AS datetime)
		SET @ETime = DATEADD(second,-1,DATEADD(day,1,@BTime))
	END
	ELSE IF @PeriodCode LIKE 'w[0-9]%' AND STUFF(@PeriodCode,1,2,'') NOT LIKE '%[^0-9]%'
	BEGIN
		SET @BTime = DATEADD(week,CAST(STUFF(@PeriodCode,1,2,'') AS int),'1900010'+SUBSTRING(@PeriodCode,2,1))
		SET @ETime = DATEADD(second,-1,DATEADD(week,1,@BTime))
	END
	ELSE IF @PeriodCode LIKE 'm[0-9][0-9][0-9][0-9][0-9][0-9]'
	BEGIN
		SET @BTime = CAST(SUBSTRING(@PeriodCode+'01',2,8) AS datetime)
		SET @ETime = DATEADD(second,-1,DATEADD(month,1,@BTime))
	END
	ELSE IF @PeriodCode LIKE 'q[0-9][0-9][0-9][0-9][1-4]'
	BEGIN
		SET @BTime = DATEADD(month,3*(CAST(RIGHT(@PeriodCode,1) AS int)-1),CAST(SUBSTRING(@PeriodCode,2,4)+'0101' AS datetime))
		SET @ETime = DATEADD(second,-1,DATEADD(month,3,@BTime))
	END
	ELSE IF @PeriodCode LIKE 'h[0-9][0-9][0-9][0-9][12]'
	BEGIN
		SET @BTime = DATEADD(month,6*(CAST(RIGHT(@PeriodCode,1) AS int)-1),CAST(SUBSTRING(@PeriodCode,2,4)+'0101' AS datetime))
		SET @ETime = DATEADD(second,-1,DATEADD(month,6,@BTime))
	END
	ELSE IF @PeriodCode LIKE 'y[0-9][0-9][0-9][0-9]'
	BEGIN
		SET @BTime = CAST(SUBSTRING(@PeriodCode,2,4)+'0101' AS datetime)
		SET @ETime = DATEADD(second,-1,DATEADD(year,1,@BTime))
	END
	ELSE
	BEGIN
		SET @BTime = NULL
		SET @ETime = NULL
	END
	INSERT INTO @PeriodDate SELECT @BTime, @ETime
	RETURN
END
GO
CREATE FUNCTION dbo.PeriodDateRange(
@PeriodCode varchar(10)
)
RETURNS varchar(30)
AS
BEGIN
	RETURN (SELECT dbo.FormatDateRange(BTime,CONVERT(char(8),ETime,112)) FROM dbo.PeriodDate(@PeriodCode))
END
GO
CREATE FUNCTION dbo.PeriodDesc(
@PeriodCode varchar(10)
)
RETURNS varchar(30)
AS
BEGIN
	RETURN CASE LEFT(@PeriodCode,1)
		WHEN 'y' THEN SUBSTRING(@PeriodCode,2,4)+'年'
		WHEN 'h' THEN SUBSTRING(@PeriodCode,2,4)+CASE WHEN RIGHT(@PeriodCode,1)='1' THEN '上半年' ELSE '下半年' END
		WHEN 'q' THEN SUBSTRING(@PeriodCode,2,4)+'年第'+RIGHT(@PeriodCode,1)+'季度'
		WHEN 'm' THEN SUBSTRING(@PeriodCode,2,4)+'/'+RIGHT(@PeriodCode,2)
		ELSE (SELECT dbo.FormatDateRange(BTime,CONVERT(char(8),ETime,112)) FROM dbo.PeriodDate(@PeriodCode))
		END
END
GO
CREATE FUNCTION dbo.PeriodCodeAdd(
@PeriodCode varchar(10),
@Add int
)
RETURNS varchar(10)
AS
BEGIN
	RETURN (
		SELECT CASE WHEN LEFT(@PeriodCode,1) = 'w' THEN dbo.PeriodCode(DATEADD(week,@Add,BTime),LEFT(@PeriodCode,2))
			ELSE dbo.PeriodCode(
				CASE LEFT(@PeriodCode,1)
					WHEN 'd' THEN DATEADD(day,@Add,BTime)
					WHEN 'm' THEN DATEADD(month,@Add,BTime)
					WHEN 'q' THEN DATEADD(month,@Add*3,BTime)
					WHEN 'h' THEN DATEADD(month,@Add*6,BTime)
					WHEN 'y' THEN DATEADD(year,@Add,BTime)
					ELSE NULL END,
				LEFT(@PeriodCode,1))
			END
		FROM dbo.PeriodDate(@PeriodCode)
		)
END
GO
