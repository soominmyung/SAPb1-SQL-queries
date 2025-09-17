/*SELECT FROM [dbo].[OIPF]  T1*/ 
/*SELECT FROM [dbo].[IPF1]  T0*/ 
/* Feb 2025 by Soomin */

-- Freight cost = Vessel + Air + Cost from GRPO
 
/* 
Landed cost and pricing support query for SAP Business One

Purpose:
Builds a per item view of landed cost at UOM level across a selected date range.
Combines freight paid post shipment and prepaid freight and converts to GBP using the daily exchange rate.
Adds a three period moving average of UOM landed cost for pricing reference.

User inputs:
- @DATE1 start date
- @DATE2 end date
- @ITEM1 to @ITEM5 item codes

Main logic:
Follows landed cost references to GRPO and AP invoice lines.
Aggregates vessel and air freight from IPF2.
Joins ORTT for USD to GBP conversion.
Brings GRPO unit price, landed cost per UOM, import duty and sugar tax.
Calculates a three row moving average of UOM landed cost per item ordered by posting date.

Output:
Item code, posting date, ETA, container number, sequence number, description, size, UOM, FTA flag, FOB in USD, 
GRPO unit price in USD, exchange rate, total freight in USD, UOM landed cost in GBP, recent wholesale sales price in GBP, 
import duty and sugar tax per UOM, three period moving average of UOM landed cost.

Confidentiality note:
No warehouse identifiers are included.
Container numbers and order sequence fields may be sensitive in some organisations. Remove or mask them if required before publishing.
Item codes can be anonymised if needed.
*/

declare @DATE1 DATETIME
declare @DATE2 DATETIME
declare @ITEM1 as NVARCHAR(20)
declare @ITEM2 as NVARCHAR(20)
declare @ITEM3 as NVARCHAR(20)
declare @ITEM4 as NVARCHAR(20)
declare @ITEM5 as NVARCHAR(20)
 
set @DATE1 = /* T1.DocDate */ '[%0]';
set @DATE2 = /* T1.DocDate */ '[%1]';
set @ITEM1 = /* T0.ItemCode */ '[%2]';
set @ITEM2 = /* T0.ItemCode */ '[%3]';
set @ITEM3 = /* T0.ItemCode */ '[%4]';
set @ITEM4 = /* T0.ItemCode */ '[%5]';
set @ITEM5 = /* T0.ItemCode */ '[%6]';
 
WITH RefCTE AS (
    SELECT 
        T0.DocEntry,
                                T0.BaseEntry,
                                T0.PriceFOB,
        T1.DocDate,
        T0.ItemCode,
                                T0.Dscription,
        T0.Quantity,
                                T0.BaseType,
                                T0.U_ImportDuty,
        T0.PriceAtWH,
                                T0.U_SugarTax,
        1 AS Level
    FROM 
        IPF1 T0
    JOIN 
        OIPF T1 ON T0.DocEntry = T1.DocEntry
    WHERE 
        (ISNULL(T1.DocDate,'') between ( CASE WHEN @DATE1 = '' THEN ISNULL(T1.DocDate,'') ELSE @DATE1 END ) AND 
                                (CASE WHEN @DATE2 = '' THEN ISNULL(T1.DocDate,'') ELSE @DATE2 END )
        AND ISNULL(Len(T1.DocDate),0) = CASE WHEN @DATE1 = '' THEN ISNULL(Len(T1.DocDate),0) ELSE Len(@DATE1) END) AND 
                                T0.ItemCode IN (@ITEM1, @ITEM2, @ITEM3, @ITEM4, @ITEM5)
    
    UNION ALL
 
    SELECT 
        T0.DocEntry,
                                T0.BaseEntry,
                                T0.PriceFOB,
        T1.DocDate,
        T0.ItemCode,
                                T0.Dscription,
        T0.Quantity,
                                T0.BaseType,
                                T0.U_ImportDuty,
        T0.PriceAtWH,
                                T0.U_SugarTax,
        cte.Level + 1
    FROM 
        IPF1 T0
    JOIN 
        OIPF T1 ON T0.DocEntry = T1.DocEntry
    INNER JOIN 
        RefCTE cte ON cte.DocEntry = T0.BaseEntry AND cte.BaseType = 69
    WHERE 
        (ISNULL(T1.DocDate,'') between ( CASE WHEN @DATE1 = '' THEN ISNULL(T1.DocDate,'') ELSE @DATE1 END ) AND 
                                (CASE WHEN @DATE2 = '' THEN ISNULL(T1.DocDate,'') ELSE @DATE2 END )
        AND ISNULL(Len(T1.DocDate),0) = CASE WHEN @DATE1 = '' THEN ISNULL(Len(T1.DocDate),0) ELSE Len(@DATE1) END) AND 
                                T0.ItemCode IN (@ITEM1, @ITEM2, @ITEM3, @ITEM4, @ITEM5)
),
LatestItemCode AS (
    SELECT DISTINCT
        cte.ItemCode,
                                cte.Dscription,
                                OITM.SWW,
                                T4.U_ETA,
                                T4.U_CNTNO,
                                T4.U_ORDNO,
                                OITM.U_HSCODE,
        cte.DocEntry,        
        cte.DocDate,
                                cte.PriceFOB,
                                T3.GPBefDisc,
        cte.Quantity,
                                cte.BaseEntry,
                                cte.U_ImportDuty,
        cte.PriceAtWH,
                                cte.U_SugarTax,
                                T2.UomCode,
                                T2.NumperMsr,
                                T4.TotalExpFc
    FROM 
        RefCTE cte
                JOIN OITM ON cte.ItemCode = OITM.ItemCode
                JOIN PDN1 T2 ON cte.BaseEntry = T2.DocEntry and cte.ItemCode = T2.ItemCode
                JOIN PCH1 T3 ON cte.ItemCode = T3.ItemCode AND cte.BaseEntry = T3.trgetEntry
                JOIN OPCH T4 ON T3.DocEntry = T4.DocEntry
                
                WHERE cte.BaseType=20
),
Temp AS (
SELECT DISTINCT
    lic.DocDate,
    lic.docEntry,
                lic.ItemCode,
                lic.U_ETA,         
                lic.U_CNTNO,
                lic.U_ORDNO,
                lic.Dscription,
                lic.sww,
    lic.UomCode,
                CASE WHEN LEN(lic.U_HSCODE) = 9 THEN 'Y' ELSE 'N' END AS [FTA],
    lic.PriceFOB,
                lic.GPBefDisc,
                CASE WHEN T5.AlcCode = 'L1' THEN T5.CostSum ELSE 0 END AS [Vessel_Freight],
                CASE WHEN T5.AlcCode = 'L2' THEN T5.CostSum ELSE 0 END AS [Air_Freight],
                lic.TotalExpFC,
                lic.PriceAtWH,
                ( lic.U_ImportDuty / lic.Quantity ) as [UOM_ImportDuty],
                ( lic.U_SugarTax / lic.Quantity ) as [UOM_SugarTax]
FROM 
    LatestItemCode lic
LEFT JOIN IPF2 T5 ON lic.DocEntry = T5.DocEntry and T5.AlcCode IN ('L1', 'L2')
),
 
Temp2 AS (SELECT DISTINCT
                tmp.DocDate,
                tmp.DocEntry,
                tmp.ItemCode,
                tmp.U_ETA as [ETA], 
                tmp.U_CNTNO,
                tmp.U_ORDNO,
                tmp.Dscription as [Description],
                tmp.sww as [Size],
    tmp.UomCode as [UOM],
                tmp.[FTA],
    tmp.PriceFOB as [FOB($)],
                tmp.GPBefDisc,
                ORTT.Rate AS Exchange_rate,
                (tmp.Vessel_Freight + tmp.Air_Freight) * ORTT.Rate AS [Freight_Cost_Postpaid($)],
                tmp.TotalExpFC AS [Freight_Cost_Prepaid($)],
                tmp.PriceAtWH as [UOM_Landed_Cost(£)],
                MAX(INV1.pricebefdi) AS [UOM_WS_Sales_Price],
                tmp.[UOM_ImportDuty],
                tmp.[UOM_SugarTax]
FROM 
    TEMP tmp
                JOIN ORTT ON tmp.DocDate = ORTT.RateDate and ORTT.Currency = 'USD'
                LEFT JOIN INV1 ON tmp.ItemCode = INV1.ItemCode AND (INV1.DocDate BETWEEN tmp.DocDate AND tmp.DocDate + 7) WHERE inv1.currency = 'GBP'
 
GROUP BY
                tmp.DocDate,
                tmp.DocEntry,
                tmp.ItemCode,
                tmp.U_ETA,     
                tmp.U_CNTNO,
                tmp.U_ORDNO,
                tmp.Dscription,
                tmp.sww,
    tmp.UomCode,
                tmp.[FTA],
    tmp.PriceFOB,
                tmp.GPBefDisc,
                ORTT.rate,
                (tmp.Vessel_Freight + tmp.Air_Freight) * ORTT.Rate,
                tmp.TotalExpFC,
                tmp.PriceAtWH,
                tmp.[UOM_ImportDuty],
                tmp.[UOM_SugarTax]
                )
 
SELECT DISTINCT
                tmp2.ItemCode,
                tmp2.docdate AS [Posting_Date],
                tmp2.ETA,        
                tmp2.U_CNTNO AS [Container_No],
                tmp2.U_ORDNO AS [Seq_No],
                tmp2.Description,
                tmp2.Size,
    tmp2.UOM,
                tmp2.FTA,
    tmp2.[FOB($)],
                tmp2.GPBefDisc AS [GRPO_Unit_Price($)],
                tmp2.Exchange_rate AS [Exchange Rate(£/$)],
                tmp2.[Freight_Cost_Postpaid($)] + tmp2.[Freight_Cost_Prepaid($)] AS [Freight_Cost($)],
                tmp2.[UOM_Landed_Cost(£)],
                tmp2.UOM_WS_Sales_Price AS [UOM_WS_Sales_Price(£)],
                MAX(tmp2.UOM_ImportDuty) AS [UOM_ImportDuty(£)],
                MAX(tmp2.UOM_SugarTax) AS [UOM_SugarTax(£)],
                tmp2.DocEntry,
				AVG(tmp2.[UOM_Landed_Cost(£)]) OVER (					PARTITION BY tmp2.ItemCode 					ORDER BY tmp2.docdate 					ROWS BETWEEN 2 PRECEDING AND CURRENT ROW				) AS [Moving_Avg_3_UOM_Landed_Cost(£)]
FROM 
    TEMP2 tmp2
 
GROUP BY       
                tmp2.ItemCode,
                tmp2.docdate,
                tmp2.ETA,        
                tmp2.U_CNTNO,
                tmp2.U_ORDNO,
                tmp2.Description,
                tmp2.Size,
    tmp2.UOM,
                tmp2.FTA,
    tmp2.[FOB($)],
                tmp2.GPBefDisc,
                tmp2.Exchange_rate,
                (tmp2.[Freight_Cost_Postpaid($)] + tmp2.[Freight_Cost_Prepaid($)]),
                tmp2.[UOM_Landed_Cost(£)],
                tmp2.UOM_WS_Sales_Price,
                tmp2.DocEntry
ORDER BY tmp2.ItemCode, tmp2.DocDate, tmp2.ETA