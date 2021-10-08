CREATE DATABASE Portfolio
GO
USE Portfolio
GO

------------------------------------------------------------------------------Cleaning Data-------------------------------------------------------------------------------------------------

/*Import Raw Database from Excel into SQL server */


------------------------ Standardise Date Format ------------------------------------------

ALTER TABLE dbo.Orders2 ALTER COLUMN [Order Date] DATE
ALTER TABLE dbo.Orders2 ALTER COLUMN [Ship Date] DATE



-------------------- Remove duplicates -------------------------------------------------------

WITH ROWNUMBER AS 
(
	SELECT *, ROW_NUMBER () OVER
	( PARTITION BY 
				[ORDER ID],
				[CUSTOMER ID],
				[CUSTOMER NAME],
				[Product ID],
				Category,
				[Product Name]

	ORDER BY [dbo].[Orders2]. [Order ID]) ROWNUMBER
	FROM ORDERS2
)
DELETE  FROM ROWNUMBER
WHERE ROWNUMBER > 1


--------------------- Drop column not used ------------------------------------------------------------

ALTER TABLE dbo.Orders2 DROP COLUMN [Ship Date] 
ALTER TABLE dbo.Orders2 DROP column [Ship Mode]


------------------------------------------------------------------------------- Create tables -----------------------------------------------------------------------------------------------------

CREATE TABLE [Product]
(
	[Product ID] VARCHAR (18) PRIMARY KEY,
	[Category] VARCHAR (16),
	[Sub-Category] VARCHAR (18),
	[Product name] NVARCHAR(225)
)

CREATE TABLE [Customers]
(
	[Customer ID] CHAR (9) PRIMARY KEY,
	[Customer Name] VARCHAR(30),
	[Segment] Varchar (12),
	[Country] VARCHAR ( 14),
	[City] VARCHAR (30),
	[State] VARCHAR (30),
	[Postal Code] VARCHAR (6),
	[Region] VARCHAR (8)
)
CREATE TABLE Orders 
(
	[Order ID] VARCHAR (15) PRIMARY KEY,
	[Customer ID] CHAR (9),
	[Order Date] DATE
	
CONSTRAINT FK_Orders FOREIGN KEY ([Customer ID]) REFERENCES dbo.Customers ([Customer ID])
)

CREATE TABLE [Order detail]
(
	[Order ID] VARCHAR (15) NOT null,
	[Product ID] VARCHAR (18) NOT null,
	[Unit price] MONEY,
	Quantity INT,
	Discount Float,
	Cost FLOAT 
CONSTRAINT PK_OrderDetail PRIMARY KEY ([Order ID],[Product ID]),
CONSTRAINT FK_OrderDetail1 FOREIGN KEY ([Product ID]) REFERENCES dbo.Product ([Product ID]),

CONSTRAINT FK_OrderDetail2 FOREIGN KEY ([Order ID]) REFERENCES dbo.Orders ([Order ID])

)


------------------Break down cleaned Table into Tables--------------------------------------------------------------------------- 

INSERT INTO dbo.Product  -- Insert data into "Product" table
SELECT DISTINCT [Product ID], Category, [Sub-Category], [Product ID] FROM dbo.Orders2 

INSERT INTO dbo.Customers -- Insert data into "Customers" Table
SELECT * FROM dbo.Customers2


INSERT INTO orders  -- Insert data into "Orders" Table
SELECT DISTINCT [Order ID],  [Customer ID], [Order Date] FROM dbo.Orders2

INSERT INTO dbo.[Order detail] -- Insert data into "Order Detail" Table
SELECT [Order ID], [Product ID], [Sales]/Quantity/(1-Discount) AS [Unit Price], Quantity, Discount,Sales -Profit AS Cost  FROM ORDERs2





------------------------------------------------------------------------------- Calculate and show Data -----------------------------------------------------------------------------------------------------



/* Looking at number of customers who have order more than once */

SELECT [Customer ID], COUNT(ord.[Customer ID]) AS [Number of purchases for each customer] FROM dbo.Orders ord 
GROUP BY [Customer ID] HAVING COUNT(ord.[Customer ID]) > 1


/* Looking at number of prodcuts sold by sub-categories */

 
SELECT [Product ID], SUM(Quantity) AS [Number of products sold by sub-categories]  FROM dbo.[Order detail] 
GROUP BY [Product ID]


/* looking at the number of prodcuts sold by categories */


SELECT [Product ID], SUM(Quantity) AS [Number of products sold by sub-categories]  FROM dbo.[Order detail] 
GROUP BY [Product ID]



-- Calculate Average order Value (AOV) 
WITH
Total_Revenue as
(
	SELECT SUM( [Unit price] * Quantity * (1 - Discount))  -- Calculate Total Revenue
	AS [Total Revenue] FROM dbo.[Order detail]  orde
)  ,

NumberofOrders AS 
(
	SELECT COUNT([Order ID])  -- Calculate number of Orders
	AS [Number of Orders] FROM dbo.Orders
) 

SELECT [Total Revenue] / [Number of Orders] AS AOV FROM Total_Revenue, NumberofOrders GO


-- Calculate Revenue from each states
SELECT   [State], SUM([Unit price] * Quantity) AS [Revenue] 
FROM dbo.[Order detail] od
JOIN dbo.Orders ord ON ord.[Order ID] = od.[Order ID]
JOIN dbo.Customers Cus ON Cus.[Customer ID] = ord.[Customer ID]
GROUP BY cus.State
ORDER BY 1



-- Showing the top 50 profitable products

SELECT TOP(50) [Order detail].[Product ID], [Product name], Category, [Sub-Category] , 
ROUND(([Unit price] * Quantity * (1-Discount) - Cost), 1 ) Profit --- Calculate profit and round to 1 decimal 
 FROM dbo.[Order detail] 
 JOIN dbo.Product ON Product.[Product ID] = [Order detail].[Product ID] 
 ORDER BY Profit DESC
 

 -- Showwing the top 50 non-profitable producs

 SELECT TOP(50) [Order detail].[Product ID], [Product name], Category, [Sub-Category] , 
ROUND(([Unit price] * Quantity * (1-Discount) - Cost), 1 ) Profit --- Calculate profit and round to 1 decimal 
 FROM dbo.[Order detail] 
 JOIN dbo.Product ON Product.[Product ID] = [Order detail].[Product ID] 
 ORDER BY Profit ASC
 
 -- Showing top 10 most-purchasing customers

 SELECT TOP (10)  Orders.[Customer ID], [Customer Name], 
 SUM([Unit price] * Quantity * (1-Discount)) AS [Total amount of money spended] -- Calculate total amount of money spended for each cusotmer
 FROM dbo.[Order detail] 
 JOIN dbo.Orders ON Orders.[Order ID] = [Order detail].[Order ID]
 JOIN dbo.Customers ON Customers.[Customer ID] = Orders.[Customer ID]
 GROUP BY Orders.[Customer ID] , [Customer Name]

 -- Showing top cities placed most orders

 SELECT City, COUNT([Order detail].[Order ID]) AS [TOTAL ORDERS] FROM dbo.[Order detail]
 JOIN dbo.Orders ON Orders.[Order ID] = [Order detail].[Order ID]
 JOIN dbo.Customers ON Customers.[Customer ID] = Orders.[Customer ID] 
 GROUP BY City 
 ORDER BY [TOTAL ORDERS] DESC
 
