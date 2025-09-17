/* Oct 2024 by Soomin */

/* 
Duplicate sales order check for SAP Business One

Purpose:
Prevents creating a duplicate sales order for the same customer and delivery date by triggering an alert in the client.

Input:
$[$4.0.0] customer code from the current form
$[$12.0.0] delivery date from the current form
$[$8.0.0] current document number

Logic:
Checks if a non cancelled sales order exists for the same customer and delivery date other than the current document.
If found returns SHOW_ERROR which prompts an alert in SAP Business One.

Output:
Returns SHOW_ERROR only when a duplicate candidate exists.
*/IF EXISTS (    SELECT 1    FROM ORDR T0    WHERE T0.CardCode = $[$4.0.0] -- Customer Code from the current form      AND T0.DocDueDate = $[$12.0.0] -- Delivery Date from the current form      AND T0.DocNum <> $[$8.0.0] -- Exclude the current document (useful for updates)      AND T0.Canceled = 'N' -- Ensure the order is not canceled)BEGINSELECT 'SHOW_ERROR' FOR BROWSEEND