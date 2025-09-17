/*SELECT FROM [dbo].[OITM] T0*/ 
/*SELECT FROM [dbo].[OWHS] T4*/ 

/*Feb 2025 by Soomin*/

/* 
Inventory availability query for SAP Business One

Purpose:  
Retrieves available stock by item and warehouse.  
Availability is calculated as OnHand - IsCommited and converted into boxes using NumInSale.  

User inputs:  
- Start item code (@ITEMCODEF)  
- End item code (@ITEMCODET)  
- Up to 11 warehouse codes (@WareHouse1 ~ @WareHouse11)  

Output:  
Item code, item name, size, main supplier, sales unit quantity, and available stock (in boxes) for each warehouse.  

Note:  
All warehouse names used in this script have been anonymised and do not represent the actual warehouse codes of the company.  
*/


declare  @ITEMCODEF as nvarchar(20) 
declare  @ITEMCODET as nvarchar(20)  
declare  @WareHouse1 as nvarchar(20) 
declare  @WareHouse2 as nvarchar(20)  
declare  @WareHouse3 as nvarchar(20) 
declare  @WareHouse4 as nvarchar(20)  
declare  @WareHouse5 as nvarchar(20) 
declare  @WareHouse6 as nvarchar(20)  
declare  @WareHouse7 as nvarchar(20)   
declare  @WareHouse8 as nvarchar(20)   
declare  @WareHouse9 as nvarchar(20)  
declare  @WareHouse10 as nvarchar(20)  
declare  @WareHouse11 as nvarchar(20) 

/* WHERE */ 

set @ITEMCODEF = /* T0.ItemCode */ '[%0]' 
set @ITEMCODET = /* T0.ItemCode */ '[%1]'  

 
if(@ITEMCODEF IS NULL or @ITEMCODEF='')
  SET @ITEMCODEF= (SELECT  MIN(ItemCode) FROM OITM)
if(@ITEMCODET IS NULL or @ITEMCODET='')
  SET @ITEMCODET= (SELECT  Max(ItemCode) FROM OITM)
if(@WareHouse1 IS NULL or @WareHouse1='')
  set  @WareHouse1='wh10'
  if(@WareHouse2 IS NULL or @WareHouse2='')
  set  @WareHouse2='wh20'
  set  @WareHouse3='wh10RES'
  set  @WareHouse4='wh20RES'
  set  @WareHouse5='bc'
  set  @WareHouse6='wh40'
  set  @WareHouse7='wh41'
  set  @WareHouse8='wh43'
  set  @WareHouse9='wh44'
  set  @WareHouse10='wh51'
  set  @WareHouse11='wh82'
	                 
SELECT     
			 T0.ItemCode							AS 'ItemCode'
			,T0.ItemName							AS 'ItemName'
			,T0.FrgnName							AS 'FrgnName'
			,T0.SWW									AS 'Item Size'	
            ,T7.CardName							AS 'Main Supplier'		
			,T0.NumInSale                           AS 'Child Qty'
			/*,T4.Whscode		*/
			, MAX( CASE WHEN  Whscode='wh10' THEN ((T4.OnHand - T4.IsCommited) / ISNULL(CASE When T0.NumInSale = 0 Then 1 Else T0.NumInSale End ,1))  END) AS [ wh10 AVAILABLE(BOX) ]
			, MAX( CASE WHEN  Whscode='wh10RES' THEN ((T4.OnHand - T4.IsCommited) / ISNULL(CASE When T0.NumInSale = 0 Then 1 Else T0.NumInSale End ,1))  END) AS [ wh10RES AVAILABLE(BOX) ]
			, MAX( CASE WHEN  Whscode='wh20' THEN ((T4.OnHand - T4.IsCommited) / ISNULL(CASE When T0.NumInSale = 0 Then 1 Else T0.NumInSale End ,1))  END) AS [ wh20 AVAILABLE(BOX) ]
			, MAX( CASE WHEN  Whscode='wh20RES' THEN ((T4.OnHand - T4.IsCommited) / ISNULL(CASE When T0.NumInSale = 0 Then 1 Else T0.NumInSale End ,1))  END) AS [ wh20RES AVAILABLE(BOX) ]
			, MAX( CASE WHEN  Whscode='bc' THEN ((T4.OnHand - T4.IsCommited) / ISNULL(CASE When T0.NumInSale = 0 Then 1 Else T0.NumInSale End ,1))  END) AS [ bc AVAILABLE(BOX) ]
			, MAX( CASE WHEN  Whscode='wh40' THEN ((T4.OnHand - T4.IsCommited) / ISNULL(CASE When T0.NumInSale = 0 Then 1 Else T0.NumInSale End ,1))  END) AS [ wh40 AVAILABLE(BOX) ]
			, MAX( CASE WHEN  Whscode='wh41' THEN ((T4.OnHand - T4.IsCommited) / ISNULL(CASE When T0.NumInSale = 0 Then 1 Else T0.NumInSale End ,1))  END) AS [ wh41 AVAILABLE(BOX) ]
			, MAX( CASE WHEN  Whscode='wh43' THEN ((T4.OnHand - T4.IsCommited) / ISNULL(CASE When T0.NumInSale = 0 Then 1 Else T0.NumInSale End ,1))  END) AS [ wh43 AVAILABLE(BOX) ]
			, MAX( CASE WHEN  Whscode='wh44' THEN ((T4.OnHand - T4.IsCommited) / ISNULL(CASE When T0.NumInSale = 0 Then 1 Else T0.NumInSale End ,1))  END) AS [ wh44 AVAILABLE(BOX) ]
			, MAX( CASE WHEN  Whscode='wh51' THEN ((T4.OnHand - T4.IsCommited) / ISNULL(CASE When T0.NumInSale = 0 Then 1 Else T0.NumInSale End ,1))  END) AS [ wh51 AVAILABLE(BOX) ]
			, MAX( CASE WHEN  Whscode='wh82' THEN ((T4.OnHand - T4.IsCommited) / ISNULL(CASE When T0.NumInSale = 0 Then 1 Else T0.NumInSale End ,1))  END) AS [ wh82 AVAILABLE(BOX) ]

			/* ,CASE WHEN T0.ManBtchNum = 'Y' THEN N'YES' ELSE '' END  AS 'BBD'	 */
	FROM OITM T0
	INNER JOIN OITW T4 ON T0.ItemCode = T4.ItemCode 
	LEFT OUTER JOIN OMRC T6   ON T0.FirmCode = T6.FIRMCODE
	LEFT OUTER JOIN OCRD T7   ON T0.CardCode = T7.CardCode
where( T0.itemcode between  @ITEMCODEF  and  @ITEMCODET ) and ( T4.WhsCode  in   (@WareHouse1 , @WareHouse2, @WareHouse3, @WareHouse4, @WareHouse5, @WareHouse6, @WareHouse7, @WareHouse8, @WareHouse9, @WareHouse10, @WareHouse11)) and len(T0.itemcode)=6

GROUP BY T0.ItemCode,ITEMNAME,FrgnName,SWW,CardName,NumInSale order by T0.ItemCode