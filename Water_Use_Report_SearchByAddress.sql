USE [CISInfinity]
GO
/****** Object:  StoredProcedure [dbo].[ConsumptionByServiceAddress]    Script Date: 9/20/2021 8:23:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Tanner
-- Create date: 09/16/2021
-- Description:	Gather Account Number and Consumption Data from Service Address
-- =============================================
ALTER PROCEDURE [dbo].[ConsumptionByServiceAddress] 
	-- Add the parameters for the stored procedure here
	@StreetNumber int, 
	@Street varchar(MAX),
	@AptNum varchar(MAX)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	CREATE table #temp1(
	CustName varchar(max)
	,CustNum varchar(max)
	,AccountNumberSA varchar(max)
	,CustAddress varchar(max)
	)

INSERT INTO #temp1
EXEC ADVANCED.SEARCHBYSERVICEADDRESS @streetNumber, @street, @AptNum, NULL

SELECT ACCOUNTNUMBER, ACCOUNTTYPECODE, ACCOUNTTYPE, ZONE_DIVISONCODE, ZONE_DIVISION, METERNUMBER, REGISTERNUMBER, CONSUMPTION, UNITS, READINGDATE, READINGMONTH, READINGDAY, READINGYEAR, READINGDAYSCOUNT, MEF321.C_LOCATION AS DEVICELOCATION
INTO #temp2 FROM water.dbo.Consumption_By_Account a
LEFT JOIN CISInfinity.ADVANCED.BIF310 ON a.ACCOUNTNUMBER = CISInfinity.ADVANCED.BIF310.C_ACCOUNT
LEFT JOIN CISInfinity.ADVANCED.MEF321 ON CISInfinity.ADVANCED.BIF310.C_DEVICE = CISInfinity.ADVANCED.MEF321.C_DEVICE
WHERE a.ACCOUNTNUMBER = (SELECT AccountNumberSA FROM #temp1
						 JOIN CISInfinity.ADVANCED.BIF003 ON #temp1.AccountNumberSA = BIF003.C_ACCOUNT
						 WHERE C_ACCOUNTSTATUS = 'AC' AND CustNum = C_CUSTOMER) 
	  AND a.READINGDATE > (SELECT D_MOVEIN FROM CISInfinity.ADVANCED.BIF003 WHERE C_CUSTOMER = (SELECT CustNum FROM #temp1
																								JOIN CISInfinity.ADVANCED.BIF003 ON #temp1.AccountNumberSA = BIF003.C_ACCOUNT
																								WHERE C_ACCOUNTSTATUS = 'AC' AND CustNum = C_CUSTOMER))

SELECT * FROM #temp2
ORDER BY READINGDATE ASC
END
