/* Nov 2024 by Soomin */

/* 
Formatted search for SAP Business One – Auto-fill HS Code

Purpose:
Retrieves the HS Code (U_HSCODE) from the item master (OITM) based on the item code in the current marketing document row.  
Used by the Korean purchasing team so that when creating AP invoices, purchase orders, or other purchasing documents, the HS Code is automatically populated.  

Input:
- $[$38.1.0] → current row ItemCode from the document matrix.  

Output:
- HS Code (U_HSCODE) from OITM.  
*/

SELECT T0.U_HSCODE
FROM OITM T0
WHERE T0.ItemCode = $[$38.1.0]
