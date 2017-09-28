-- ================================================
-- Template generated from Template Explorer using:
-- Create Procedure (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the procedure.
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE UpdateStockStatus
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    --Synchronize the target table with
    --refreshed data from source table
	MERGE StatusUpdate AS TARGET
	USING stockstatus AS SOURCE 
	ON (TARGET.ItemNo = SOURCE.ItemNo) 
	--When records are matched, update 
	--the records if there is any change
	WHEN MATCHED THEN 
	UPDATE SET 
	  TARGET.ItemNo = SOURCE.ItemNo, 
	  TARGET.OutOfStockDate =    
		CASE
		  WHEN SOURCE.Stock = 'no' THEN SOURCE.CurrentDate
		  ELSE TARGET.OutOfStockDate
		END,
	   TARGET.InStockDate =	    
		CASE
		  WHEN SOURCE.Stock = 'yes' THEN SOURCE.CurrentDate
		  ELSE TARGET.InStockDate
		END,
		TARGET.EndedDate =	    
		CASE
		  WHEN SOURCE.Stock = 'ended' THEN SOURCE.CurrentDate
		  ELSE TARGET.EndedDate
		END,
	  TARGET.DateModified = GETDATE()

	WHEN NOT MATCHED BY TARGET THEN 
	INSERT (ItemNo, OutOfStockDate, InStockDate, EndedDate, DateModified) 
	VALUES (SOURCE.ItemNo, null, SOURCE.CurrentDate, null, GETDATE());
	SELECT @@ROWCOUNT;
END
GO
