/*SELECT FROM [dbo].[PCH1]  T0*/
/*SELECT FROM [dbo].[OPCH]  T1*/
/* Soomin Nov 2024 */

/* 
First import items history query for SAP Business One

Purpose:
Identifies items appearing for the first time in import AP invoices.  
Useful for tracking initial purchase history of imported goods, including arrival time and shipment details.  

Input:
- @INVOICENUM: AP invoice number

Logic:
- TEMP CTE collects shipment-related metadata (ATA date/time, container number, order number) from AP invoices (OPCH) and links to purchase orders.  
- Main query checks whether an item has appeared in any previous AP invoice. If not, marks it as "***New***".  
- Output combines item details with remarks (ATA date, supplier, order no, container no).  

Output:
- Status (***New*** for first import), ItemCode, Description, Quantity, Size, ATA time, and Remarks.  

Notes:
- Table and column names follow SAP B1 structure.  
- User-defined fields (U_ACT, U_ACTTime, U_ORDER, U_CONT, U_SHIPPING) are illustrative and anonymised. Replace or rename if required.  
*/

DECLARE @INVOICENUM AS VARCHAR(40) 
SET @INVOICENUM = /* T1.DocNum */ '[%0]';

WITH TEMP AS (
SELECT DISTINCT
      CH.U_ACT, CH.U_ORDER, CH.U_CONT, CH.DocNum,
      case when Len(CH.U_ACTTime) = 1 then replace(CH.U_ACTTime, '0', NULL) else CH.U_ACTTime end as U_ACTTime
    from 
      OPCH CH 
      INNER JOIN PCH1 PC on PC.DocEntry = CH.DocEntry 
      AND CH.isIns = 'Y' 
      AND CH.CANCELED <> 'Y' 
      and CH.CANCELED <> 'C' 
      LEFT JOIN OPOR OP ON PC.BaseEntry = OP.DocEntry 
      and PC.BaseType = OP.ObjType 
      and OP.WddStatus NOT IN ('W', 'C', 'N') 
      and OP.CANCELED <> 'Y' 
      LEFT JOIN POR1 ON OP.DocEntry = POR1.DocEntry 
      LEFT JOIN OITM ON OITM.ItemCode = PC.ItemCode 
    where 
      1 = case when POR1.TargetType =-1 
      AND OP.DocStatus = 'C' then 2 else 1 end 
      AND CH.U_SHIPPING = 'I' 
	  AND CH.DocNum = @INVOICENUM
)
SELECT 

  CASE
           WHEN NOT EXISTS
                    (
                        SELECT 1
                        FROM PCH1 T2
                        WHERE T2.ItemCode = T0.ItemCode
                              AND T2.DocEntry <> T0.DocEntry
							  AND T2.DocDate < T0.DocDate
                    ) THEN
               '***New***' ELSE '' END AS Status,
  T0.ItemCode AS 'ItemCode', 
  T0.Dscription AS 'Description', 
  T0.Quantity AS 'Qty',
  T0.U_SWW AS 'Size',
  TEMP.U_ACTTIME AS 'ATA Time',
  (COALESCE(CAST(FORMAT(TEMP.U_ACT, 'dd/MM/yyyy') AS VARCHAR(20)), '') + ' ' + COALESCE(T1.CardName, '') + ' ' + (CASE WHEN COALESCE(TEMP.U_ORDER, '') = '' THEN '' ELSE '#' + TEMP.U_ORDER END) 
  + ' (' + COALESCE(TEMP.U_CONT, '') + ')') AS Remarks
FROM 
  PCH1 T0 
  JOIN OPCH T1 ON T0.DocEntry = T1.DocEntry 
  JOIN TEMP ON T1.DocNum = TEMP.DocNum
WHERE 
  T1.DocNum = @INVOICENUM
ORDER BY Status DESC