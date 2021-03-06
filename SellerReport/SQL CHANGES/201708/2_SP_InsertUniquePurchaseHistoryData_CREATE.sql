
/****** Object:  StoredProcedure [dbo].[UpdateStockStatus]    Script Date: 8/9/2017 4:43:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[InsertUniquePurchaseHistoryData]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    MERGE SellerDataHistory AS TARGET
	USING purchasehistory AS SOURCE 
	ON (TARGET.ItemNo = SOURCE.ItemNo 
		AND TARGET.SellerName = SOURCE.SellerName
		AND TARGET.CategoryNo = SOURCE.CategoryNo
		AND TARGET.Title = SOURCE.Title
		AND TARGET.Price = SOURCE.Price
		AND TARGET.Quantity = SOURCE.Quantity
		AND TARGET.Variations = SOURCE.Variations
		AND TARGET.ShippingCost = SOURCE.ShippingCost
		AND TARGET.Watchers = SOURCE.Watchers
		AND TARGET.DateListed = SOURCE.DateListed
		AND TARGET.Date = SOURCE.Date
		AND TARGET.Time = SOURCE.Time
		AND TARGET.DaysSince = SOURCE.DaysSince
		AND TARGET.Feedback = SOURCE.Feedback
		AND TARGET.ImageURL = SOURCE.ImageURL)

	WHEN NOT MATCHED BY TARGET THEN 
	INSERT (ItemNo, SellerName, CategoryNo, Title, Price, Quantity, Variations, ShippingCost, Watchers, DateListed, Date, Time, DaysSince, Feedback, ImageURL) 
	VALUES (SOURCE.ItemNo, SOURCE.SellerName, SOURCE.CategoryNo, SOURCE.Title, SOURCE.Price, SOURCE.Quantity, SOURCE.Variations, SOURCE.ShippingCost, SOURCE.Watchers, SOURCE.DateListed, SOURCE.Date, SOURCE.Time, SOURCE.DaysSince, SOURCE.Feedback, SOURCE.ImageURL);
	SELECT @@ROWCOUNT;
END
