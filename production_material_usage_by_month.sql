/*SELECT * FROM [DBO].[OWOR] T0 */
/* FEB 2025 Soomin */

/* 
Production material usage tracker for SAP Business One

Purpose:
Aggregates issued quantities of component materials used in work orders for a specified finished item over the last twelve months, and adds the current inventory for each component.

User inputs:
- @ItemCode as the finished item to analyse
- The script derives the last twelve months from the current date

Source tables:
OWOR work orders, WOR1 work order lines, OITM item master, OITW item by warehouse stock, ITT1 bill of materials components.

Logic:
Builds month columns dynamically for the last twelve months. Counts material usage as the sum of WOR1.IssuedQty per month per component where OWOR.Status is L and the work order start date is within the window. Components are taken from ITT1 for the given finished item. The query also joins current inventory from OITW for each component.

Output:
One row per finished item and component with twelve month columns formatted as MMM yyyy and a Current Inventory column.

Confidentiality note:
Item codes shown in any hard coded lists are placeholders for demonstration. Replace them with anonymised values or parameterise them before publishing. No real warehouse identifiers are used in this script.
*/

DECLARE @ItemCode AS NVARCHAR(50) 
SET @ItemCode = /* T0.ItemCode */ '[%0]';
DECLARE @StartDate DATE = DATEADD(YEAR, -1, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1));
DECLARE @SQLQuery NVARCHAR(MAX);
DECLARE @Columns NVARCHAR(MAX) = '';

-- Generate column names dynamically for the last 12 months
DECLARE @i INT = 11;
WHILE @i >= 0
BEGIN
    SET @Columns = @Columns + ', SUM(CASE WHEN MonthValue = ''' + FORMAT(DATEADD(MONTH, -@i, GETDATE()), 'yyyy-MM') + ''' THEN Usage ELSE 0 END) AS [' + FORMAT(DATEADD(MONTH, -@i, GETDATE()), 'MMM yyyy') + ']';
    SET @i = @i - 1;
END

-- Construct the full SQL query
SET @SQLQuery = '
WITH MonthlyUsage AS (
    SELECT 
        OWOR.ItemCode AS Father, 
        WOR1.ItemCode AS Material,
		OITM.ItemName AS Material_Name,
        FORMAT(OWOR.StartDate, ''yyyy-MM'') AS MonthValue,
        SUM(WOR1.IssuedQty) AS Usage
    FROM OWOR 
    JOIN WOR1 ON OWOR.DocEntry = WOR1.DocEntry 
	JOIN OITM ON WOR1.ItemCode = OITM.ItemCode
    WHERE (WOR1.ItemCode IN (SELECT ITT1.Code FROM ITT1 WHERE ITT1.Father = ''' + @ItemCode + ''') OR WOR1.ItemCode IN (''303030'', ''101010'', ''404040'') )
        AND OWOR.ItemCode = ''' + @ItemCode + ''' 
        AND OWOR.Status = ''L'' 
        AND OWOR.StartDate >= ''' + CONVERT(NVARCHAR, @StartDate, 23) + '''
    GROUP BY OWOR.ItemCode, WOR1.ItemCode, OITM.ItemName, FORMAT(OWOR.StartDate, ''yyyy-MM'')
),
InventoryData AS (
    SELECT 
        OITW.ItemCode AS Material,
        SUM(OITW.OnHand) AS CurrentInventory
    FROM OITW
    WHERE OITW.ItemCode IN (SELECT ITT1.Code FROM ITT1 WHERE ITT1.Father = ''' + @ItemCode + ''') OR OITW.ItemCode IN (''303030'', ''101010'', ''404040'') 
    GROUP BY OITW.ItemCode
)
SELECT 
    MU.Father,
    MU.Material,
	MU.Material_name'
    + @Columns + ',
    COALESCE(ID.CurrentInventory, 0) AS [Current Inventory]
FROM MonthlyUsage MU
LEFT JOIN InventoryData ID ON MU.Material = ID.Material
GROUP BY MU.Father, MU.Material, MU.Material_Name, ID.CurrentInventory
ORDER BY MU.Father, MU.Material;
';

-- Execute the dynamically generated SQL
EXEC sp_executesql @SQLQuery;

select top 10 * from WOR1