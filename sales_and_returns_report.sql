/* select * FROM OINV T0 */
/* select * FROM INV1 T1 */
/* select * FROM OITM T2 */
/* select * FROM [@UPI_BPGROUP] T3 */
/* Soomin Feb 2025 */

/* 
Invoice and credit memo line explorer for SAP Business One

Purpose:
Returns invoice and credit memo lines with flexible filters by business partner and item,
and a total quantity summary row.

Inputs:
@clientgroup, @clientcode, @clientname, @FRDATE, @TODATE, @itemcode, @itemname, @frgname

Notes:
- User-defined objects and fields anonymised
- Channel and code-prefix rules are illustrative
*/

declare @clientcode nvarchar(20)
declare @clientname nvarchar(20)
declare @FRDATE DATETIME
declare @TODATE DATETIME
declare @itemcode nvarchar(20) 
declare @itemname nvarchar(20) 
declare @frgname nvarchar(20) 
declare @clientgroup nvarchar(20)

set @clientgroup = /* T3.U_BP_TYPE */ '[%0]'
set @clientcode = /* T0.CardCode  */ '[%1]' 
set @clientname = /* T0.CardName  */ '[%2]' 
set @FRDATE = /* T0.TaxDATE  */ '[%3]' 
set @TODATE = /* T0.TaxDATE  */ '[%4]' 
set @itemcode = /* T1.ItemCode  */ '[%5]' 
set @itemname = /* T2.itemName  */ '[%6]' 
set @frgname = /* T2.FrgnName  */ N'[%7]'

if(@clientcode IS NULL or @clientcode='')
  set  @clientcode='%'
if(@clientname IS NULL or @clientname='')
  set  @clientname='%'
if(@itemcode IS NULL or @itemcode='')
  set  @itemcode='%'
  if(@FRDATE IS NULL or @FRDATE='')
  set  @FRDATE='01/01/19'
if(@TODATE IS NULL or @TODATE='')
  set  @TODATE=getdate()
if(@itemcode IS NULL or @itemcode='')
  set  @itemcode='%'
if(@itemname IS NULL or @itemname='')
  set  @itemname='%'
if(@frgname IS NULL or @frgname='')
  set  @frgname='%'


/* First OINV */

SELECT   T0.[Taxdate] as DocDate, T0.[CardCode] as 'Customer Code', T0.[CardName] as 'Customer Name', T1.[ItemCode],T1.[Dscription],
T2.[FrgnName],T1.[unitMsr] as'UoM', T1.[Quantity], T1.[Price], T1.[DiscPrcnt], T0.[DocNum], T0.[ObjType],T0.[DocEntry],T3.[Descr] AS 'Credit Category'

FROM OINV T0 
LEFT JOIN UFD1 T3 on T3.[FldValue] = T0.[U_CreditCat]
                   and T3.TableID='OINV' and fieldID=999
INNER JOIN INV1 T1 ON T0.[DocEntry] = T1.[DocEntry]
INNER JOIN OITM T2 ON T1.[ItemCode] = T2.[ItemCode]

WHERE T0.canceled='N' 
AND T0.CardCode like @clientcode 
AND T0.CardName LIKE @clientname

AND

(

T0.Taxdate >= @FRDATE AND  CAST(T0.Taxdate as DATE) <= (CASE WHEN YEAR(@TODATE) = 1753 then CAST(GETDATE() AS DATE) ELSE @TODATE END )

)

AND T1.ItemCode like @itemcode 
AND T1.Dscription like N'%' +@itemname+ '%'
AND T2.[FrgnName] like N'%' + @frgname + '%'
AND T0.CardCode LIKE (CASE WHEN @clientgroup = 'Customer' THEN 'C%'        WHEN @clientgroup = 'kplaza' THEN 'P%'		WHEN @clientgroup = 'Supplier' THEN 'S%'		WHEN @clientgroup = 'util' THEN 'Y%'		ELSE '%' END) 
AND T0.CardName LIKE (CASE WHEN @clientgroup = 'ecomm' THEN '%ecomm%' ELSE '%' END)

union all

/* First ORIN */

SELECT   T0.[Taxdate] as DocDate, T0.[CardCode] as 'Customer Code', T0.[CardName] as 'Customer Name', T1.[ItemCode],T1.[Dscription],
T2.[FrgnName],T1.[unitMsr] as'UoM', T1.[Quantity]*(-1), T1.[Price], T1.[DiscPrcnt], T0.[DocNum], T0.[ObjType],T0.[DocEntry],T3.[Descr] AS 'Credit Category'
FROM ORIN T0 
LEFT JOIN UFD1 T3 on T3.[FldValue] = T0.[U_CreditCat]
                   and T3.TableID='ORIN' and fieldID=999
INNER JOIN RIN1 T1 ON T0.[DocEntry] = T1.[DocEntry]
INNER JOIN OITM T2 ON T1.[ItemCode] = T2.[ItemCode]
WHERE T0.canceled='N' and T0.CardCode like @clientcode AND T0.CardName LIKE @clientname
AND

(
T0.Taxdate >= @FRDATE AND  CAST(T0.Taxdate as DATE) <= (CASE WHEN YEAR(@TODATE) = 1753 then CAST(GETDATE() AS DATE) ELSE @TODATE END )
)

AND T1.ItemCode like @itemcode
AND T1.Dscription like N'%'+@itemname + '%'
AND T2.[FrgnName] like N'%'+ @frgname + '%'
AND T0.CardCode LIKE (CASE WHEN @clientgroup = 'Customer' THEN 'C%'        WHEN @clientgroup = 'kplaza' THEN 'P%'		WHEN @clientgroup = 'Supplier' THEN 'S%'		WHEN @clientgroup = 'util' THEN 'Y%'		ELSE '%' END)
AND T0.CardName LIKE (CASE WHEN @clientgroup = 'ecomm' THEN '%ecomm%' ELSE '%' END)

UNION ALL

SELECT      NULL AS 'Posting Date',     @clientgroup AS 'Customer Code',     'Total' AS 'Customer Name',     NULL AS 'ItemCode',     NULL AS 'Dscription',     NULL AS 'FrgnName',     NULL AS 'UoM',     SUM(Quantity) AS Total_Quantity,     NULL AS 'Price',    NULL AS 'Discount % for Document',     NULL AS 'Document Number',     NULL AS 'Object Type',     NULL AS 'Internal Number',     NULL AS 'Credit Category'
FROM (

SELECT   T0.[Taxdate] as DocDate, T0.[CardCode] as 'Customer Code', T0.[CardName] as 'Customer Name', T1.[ItemCode],T1.[Dscription],
T2.[FrgnName],T1.[unitMsr] as'UoM', T1.[Quantity], T1.[Price], T1.[DiscPrcnt], T0.[DocNum], T0.[ObjType],T0.[DocEntry],T3.[Descr] AS 'Credit Category'

FROM OINV T0 
LEFT JOIN UFD1 T3 on T3.[FldValue] = T0.[U_CreditCat]
                   and T3.TableID='OINV' and fieldID=999
INNER JOIN INV1 T1 ON T0.[DocEntry] = T1.[DocEntry]
INNER JOIN OITM T2 ON T1.[ItemCode] = T2.[ItemCode]

WHERE T0.canceled='N' and T0.CardCode like @clientcode AND T0.CardName LIKE @clientname

AND

(

T0.Taxdate >= @FRDATE AND  CAST(T0.Taxdate as DATE) <= (CASE WHEN YEAR(@TODATE) = 1753 then CAST(GETDATE() AS DATE) ELSE @TODATE END )

)

AND T1.ItemCode like @itemcode 
AND T1.Dscription like N'%' +@itemname+ '%'
AND T2.[FrgnName] like N'%' + @frgname + '%'
AND T0.CardCode LIKE (CASE WHEN @clientgroup = 'Customer' THEN 'C%'        WHEN @clientgroup = 'kplaza' THEN 'P%'		WHEN @clientgroup = 'Supplier' THEN 'S%'		WHEN @clientgroup = 'util' THEN 'Y%'		ELSE '%' END) 
AND T0.CardName LIKE (CASE WHEN @clientgroup = 'ecomm' THEN '%ecomm%' ELSE '%' END)

union all

SELECT   T0.[Taxdate] as DocDate, T0.[CardCode] as 'Customer Code', T0.[CardName] as 'Customer Name', T1.[ItemCode],T1.[Dscription],
T2.[FrgnName],T1.[unitMsr] as'UoM', T1.[Quantity]*(-1), T1.[Price], T1.[DiscPrcnt], T0.[DocNum], T0.[ObjType],T0.[DocEntry],T3.[Descr] AS 'Credit Category'
FROM ORIN T0 
LEFT JOIN UFD1 T3 on T3.[FldValue] = T0.[U_CreditCat]
                   and T3.TableID='ORIN' and fieldID=999
INNER JOIN RIN1 T1 ON T0.[DocEntry] = T1.[DocEntry]
INNER JOIN OITM T2 ON T1.[ItemCode] = T2.[ItemCode]
WHERE T0.canceled='N' and T0.CardCode like @clientcode AND T0.CardName LIKE @clientname
AND

(
T0.Taxdate >= @FRDATE AND  CAST(T0.Taxdate as DATE) <= (CASE WHEN YEAR(@TODATE) = 1753 then CAST(GETDATE() AS DATE) ELSE @TODATE END )
)

AND T1.ItemCode like @itemcode
AND T1.Dscription like N'%'+@itemname + '%'
AND T2.[FrgnName] like N'%'+ @frgname + '%'
AND T0.CardCode LIKE (CASE WHEN @clientgroup = 'Customer' THEN 'C%'        WHEN @clientgroup = 'kplaza' THEN 'P%'		WHEN @clientgroup = 'Supplier' THEN 'S%'		WHEN @clientgroup = 'util' THEN 'Y%'		ELSE '%' END)
AND T0.CardName LIKE (CASE WHEN @clientgroup = 'ecomm' THEN'%ecomm%' ELSE '%' END)) as Temp