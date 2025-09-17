/* May 2025 by Soomin */
/* 
Business Partner Group initialisation script for SAP Business One

Purpose:  
Creates entries in the user-defined table [@upi_bpgroup] to categorise business partners.  

Details:  
Each record has:  
- Code: numeric identifier  
- Name: display name of the group  
- U_BP_Type: user-defined type label  

The script inserts five example groups: Customer, SeoulPlaza, Supplier, Utility, and Online.  
*/

select * from [@upi_bpgroup]

insert into [@upi_bpgroup] (Code, Name, U_BP_Type) VALUES (0, 'Customer', 'Customer')
insert into [@upi_bpgroup] (Code, Name, U_BP_Type) VALUES (1, 'SeoulPlaza', 'SeoulPlaza')
insert into [@upi_bpgroup] (Code, Name, U_BP_Type) VALUES (2, 'Supplier', 'Supplier')
insert into [@upi_bpgroup] (Code, Name, U_BP_Type) VALUES (3, 'Utility', 'Utility')
insert into [@upi_bpgroup] (Code, Name, U_BP_Type) VALUES (4, 'Online', 'Online')
