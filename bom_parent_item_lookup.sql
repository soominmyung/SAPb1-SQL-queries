/*SELECT * FROM [DBO].[OWOR] T0 */
/* FEB 2025 Soomin */

/* 
Find parent items (finished goods or semi-finished goods) that use a given component in their Bill of Materials (BOM). 

Input: @ItemCode (component). 

Output: Parent item code, description, required quantity, and warehouse. 
*/

DECLARE @ITEMCODE NVARCHAR(50)
SET @ItemCode = /* T0.ItemCode */ '[%0]';

SELECT 
    ITT1.Father AS Parent_Item,   -- The finished good (BoM parent)
    OITM.ItemName AS Parent_Item_Description,
    ITT1.Code AS Component_Item,  -- The component used 
    OITM2.ItemName AS Component_Item_Description,
    ITT1.Quantity AS Required_Quantity,  -- How much is needed per production
    ITT1.Warehouse AS Warehouse
FROM ITT1
JOIN OITM OITM ON ITT1.Father = OITM.ItemCode   -- Parent item details
JOIN OITM OITM2 ON ITT1.Code = OITM2.ItemCode   -- Component item details
WHERE ITT1.Code = @ITEMCODE
ORDER BY ITT1.Father;
