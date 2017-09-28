


ALTER PROCEDURE [dbo].[GetSellerReport]
	@date DATETIME,
	@title VARCHAR(2000),
	@operator VARCHAR(10),
	@value FLOAT
AS
BEGIN
	SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#nonulldates') IS NOT NULL
	  DROP TABLE #nonulldates
	IF OBJECT_ID('tempdb..#nulldates') IS NOT NULL
	  DROP TABLE #nulldates
	IF OBJECT_ID('tempdb..#nonulldatesrank') IS NOT NULL
	  DROP TABLE #nonulldatesrank
	IF OBJECT_ID('tempdb..#sellerdatawithlastsaledate') IS NOT NULL
	  DROP TABLE #sellerdatawithlastsaledate
	IF OBJECT_ID('tempdb..#sellerbasedata') IS NOT NULL
	  DROP TABLE #sellerbasedata
	IF OBJECT_ID('tempdb..#sellerdatawithTotalUnitsSold30Days') IS NOT NULL
	  DROP TABLE #sellerdatawithTotalUnitsSold30Days
	IF OBJECT_ID('tempdb..#sellerdatawithTotalNumberOfUnitsSoldBetweenLastStockedAndLastSaleDate') IS NOT NULL
	  DROP TABLE #sellerdatawithTotalNumberOfUnitsSoldBetweenLastStockedAndLastSaleDate
	IF OBJECT_ID('tempdb..#TitleExclude') IS NOT NULL
	  DROP TABLE #TitleExclude

	SELECT Item
	INTO #TitleExclude
	FROM dbo.SplitString(@title, ',')

	SELECT ItemNo,[date]
	INTO #nonulldates
	FROM PurchaseHistory
	where [date] is not null AND [date] <> ''

	SELECT ItemNo,[date]
	INTO #nonulldatesrank
	FROM
	(SELECT ItemNo, [Date],
	  row_number() over ( partition by ItemNo order by convert(datetime,[date],111) desc) r 
	FROM #nonulldates
	)
	A
	WHERE r = 1

	SELECT DISTINCT ItemNo,[date]
	INTO #nulldates
	FROM PurchaseHistory
	where [date] is null OR [date] = ''

	SELECT DISTINCT ItemNo,[Date]
	INTO #sellerdatawithlastsaledate
	FROM
	(
	SELECT *
	FROM #nonulldatesrank
	UNION ALL
	SELECT * 
	FROM #nulldates
	) A
 
	SELECT *
	INTO #sellerbasedata
	FROM
	(
		SELECT A.sellername,A.itemno,A.title, A.Quantity,B.Date AS DateLastSale, A.[Date]
		FROM PurchaseHistory A
			LEFT JOIN #sellerdatawithlastsaledate  B
			ON B.ItemNo = A.ItemNo
		WHERE convert(varchar,convert(datetime ,A.[date]),111) <= convert(varchar,convert(date, @date) ,111) 

		UNION ALL 

		SELECT A.sellername,A.itemno,A.title, A.Quantity, B.Date AS DateLastSale,A.[Date]
		FROM PurchaseHistory A
			LEFT JOIN #sellerdatawithlastsaledate  B
			ON B.ItemNo = A.ItemNo
		WHERE  A.[date] is null OR A.[date] = ''
	)A
	GROUP BY sellername,A.itemno,title, DateLastSale, Quantity,Date
	
	
	SELECT ItemNo, ISNULL(SUM(CAST(Quantity AS INT)),0) AS TotalUnitsSold30Days
	INTO #sellerdatawithTotalUnitsSold30Days
	FROM purchasehistory
	WHERE convert(datetime,[date],111) between convert(date,DATEADD(day,-30,@date) ,111)  and convert(varchar,convert(date, @date) ,111)
	GROUP BY ItemNo
	
	DECLARE @strQuery VARCHAR(MAX)
	SET @strQuery = ''

	IF(@operator <> '' AND @value <> '')
	BEGIN
		IF(@operator = 'Equals')
		   SET @operator = '='

		IF (@title <> '')
		BEGIN
			SET @strQuery = 
				N'SELECT SellerName, A.ItemNo, Title, ISNULL(SUM(CAST(Quantity AS INT)),0) AS TotalQuantitySold, DateLastSale,--DateLastStocked,
				  TotalUnitsSold30Days
				FROM #sellerbasedata A
				LEFT JOIN #sellerdatawithTotalUnitsSold30Days B ON B.ItemNo = A.ItemNo
				WHERE NOT EXISTS (select 1 from #TitleExclude Ex where A.Title LIKE ''%'' + Ex.Item + ''%'') ' + 
				' AND B.TotalUnitsSold30Days ' +  CAST(@operator AS VARCHAR(5)) + ' ' + CAST(@value AS VARCHAR(5)) + 
				' GROUP BY sellername,A.itemno,title, DateLastSale,B.TotalUnitsSold30Days '			
			
		END
		ELSE
		BEGIN
			SET @strQuery = 
				N'SELECT SellerName, A.ItemNo, Title, ISNULL(SUM(CAST(Quantity AS INT)),0) AS TotalQuantitySold, DateLastSale,--DateLastStocked,
				  TotalUnitsSold30Days
				FROM #sellerbasedata A
				LEFT JOIN #sellerdatawithTotalUnitsSold30Days B ON B.ItemNo = A.ItemNo' + 
				' WHERE B.TotalUnitsSold30Days '  +  CAST(@operator AS VARCHAR(5)) + ' ' + CAST(@value AS VARCHAR(5)) +  
				' GROUP BY sellername,A.itemno,title, DateLastSale,B.TotalUnitsSold30Days '
		END
	END
	ELSE
	BEGIN
		IF (@title <> '')
		BEGIN
		    SET @strQuery = 
				N'SELECT SellerName, A.ItemNo, Title, ISNULL(SUM(CAST(Quantity AS INT)),0) AS TotalQuantitySold, DateLastSale,--DateLastStocked,
				  TotalUnitsSold30Days
				FROM #sellerbasedata A
				LEFT JOIN #sellerdatawithTotalUnitsSold30Days B ON B.ItemNo = A.ItemNo
				WHERE NOT EXISTS (select 1 from #TitleExclude Ex where A.Title LIKE ''%'' + Ex.Item + ''%'')
				GROUP BY sellername,A.itemno,title, DateLastSale,B.TotalUnitsSold30Days'
		END
		ELSE
		BEGIN
		    SET @strQuery =
				N'SELECT SellerName, A.ItemNo, Title, ISNULL(SUM(CAST(Quantity AS INT)),0) AS TotalQuantitySold, DateLastSale,--DateLastStocked,
				  TotalUnitsSold30Days
				FROM #sellerbasedata A
				LEFT JOIN #sellerdatawithTotalUnitsSold30Days B ON B.ItemNo = A.ItemNo
				GROUP BY sellername,A.itemno,title, DateLastSale,B.TotalUnitsSold30Days'
		END
	END

	PRINT @strQuery
 
	EXEC(@strQuery)

END



GO


