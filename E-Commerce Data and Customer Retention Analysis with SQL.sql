
--------------E-Commerce Data and Customer Retention Analysis with SQL-----------------------------------

SELECT *
FROM [dbo].[market_facts]

SELECT *
FROM [dbo].[orders_dimen]


SELECT *
FROM[dbo].[shipping_dimen]

SELECT *
FROM [dbo].[cust_dimen]

SELECT *
FROM[dbo].[prod_dimens]

-----------Cust_100 like columns are candidate to be PK, they have unique items but characters are string so we need to clean and alter them to int.


UPDATE cust_dimen
SET Cust_id = REPLACE(Cust_id,'Cust_','')


SELECT *
FROM cust_dimen

ALTER TABLE cust_dimen ALTER COLUMN [Cust_id] INT
-------------------

UPDATE [dbo].[prod_dimens]
SET [Prod_id] = REPLACE(Prod_id,'Prod_','')

SELECT *
FROM [dbo].[prod_dimens]

ALTER TABLE prod_dimens ALTER COLUMN [Prod_id] INT

--------


UPDATE [dbo].[shipping_dimen]
SET [Ship_id] = REPLACE(Ship_id,'SHP_','')

SELECT *
FROM [dbo].[shipping_dimen]

ALTER TABLE [shipping_dimen] ALTER COLUMN [Ship_id] INT

------------


UPDATE [dbo].[orders_dimen]
SET [Ord_id]= REPLACE([Ord_id],'Ord_','')

SELECT *
FROM [dbo].[orders_dimen]

ALTER TABLE [dbo].[orders_dimen] ALTER COLUMN [Ord_id] INT


-----------------------------
UPDATE market_facts
SET Ord_id = REPLACE(Ord_id,'Ord_','')


UPDATE market_facts
SET Prod_id = REPLACE(Prod_id,'Prod_','')

UPDATE market_facts
SET Ship_id = REPLACE(Ship_id,'SHP_','')

UPDATE market_facts
SET Cust_id = REPLACE(Cust_id,'Cust_','')

SELECT *
FROM [dbo].[market_facts]


----data types are nvarchar, altering the to int;

ALTER TABLE [dbo].[market_facts] ALTER COLUMN Ord_id INT
ALTER TABLE [dbo].[market_facts] ALTER COLUMN Prod_id INT
ALTER TABLE [dbo].[market_facts] ALTER COLUMN Ship_id INT
ALTER TABLE [dbo].[market_facts] ALTER COLUMN Cust_id INT
--------------------------------------------------
ALTER TABLE [dbo].[cust_dimen] ALTER COLUMN Cust_id INT
ALTER TABLE [dbo].[orders_dimen] ALTER COLUMN Ord_id INT
ALTER TABLE [dbo].[prod_dimen] ALTER COLUMN Prod_id INT
ALTER TABLE [dbo].[shipping_dimen] ALTER COLUMN Ship_id INT



----------------------------- checking uniqueness
SELECT 
CASE 
WHEN COUNT(distinct Ship_id)= COUNT(Ship_id)
THEN 'column values are unique' 
ELSE 'column values are NOT unique' 
END
FROM [shipping_dimen];
-------------------------------

---PK and FK  assignments done by Query Designer, or it could be done;

ALTER TABLE [dbo].[market_facts]
ADD FOREIGN KEY (Prod_id) 
REFERENCES [dbo].[prod_dimens](Prod_id);



	-------- get the data type of all the columns----
SELECT 
	TABLE_CATALOG
	, TABLE_SCHEMA
	, TABLE_NAME
	, COLUMN_NAME
	, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS
------------------------------------------------------
---Denormalized, star shaped, facts and dimensions,
/*
Types of Database Schemas;
Physical Database Schema.
Logical Database Schema.
View Database Schema.
Star Schema.
Snowflake Schema.
*/
/*
Fact tablosu, temel olarak, dimenson tablolarındaki PRIMARY KEY'lere atıfta bulunan ;
measurements/facts ve
FOREIGN KEY lerden oluşur.
Fact tablosu, dimenson bir modelde birincil tablodur (primary table)
Bir Dimenson tablosu, temel olarak text alanları olan descriptive (tanımlayıcı) niteliklerden oluşur.
Bir FOREIGN KEY aracılığıyla Fact tablosuna join edilirler.
Dimension tablolar normalize edilmemiş tablolardır.
Dimenson'lar, niteliklerinin (attributes) yardımıyla fact'lerin descriptive karakteristiklerini sunar.
Dimenson ayrıca bir veya daha fazla hiyerarşik ilişki (relationship) içerebilir
*/

--1. Join all the tables and create a new table called combined_table. (market_fact, cust_dimen, orders_dimen, prod_dimen, shipping_dimen)

SELECT * 
INTO   combined_table
FROM 
(SELECT 
		A.[Ord_id]
	  , A.[Prod_id]
	  , A.[Ship_id]
	  , A.[Cust_id]
	  , A.[Sales], A.[Discount]
	  , A.[Order_Quantity]
	  , A.[Product_Base_Margin]
	  , B.[Customer_Name]
	  , B.[Province]
	  , B.[Region]
	  , B.[Customer_Segment]
	  , C.[Order_Date]
	  , C.[Order_Priority]
	  , D.[Product_Category]
	  , D.[Product_Sub_Category]
	  , E.[Order_ID]
	  , E.[Ship_Mode]
	  , E.[Ship_Date]
FROM [dbo].[market_facts] A
JOIN  [dbo].[cust_dimen] B on A.Cust_id = B.Cust_id
JOIN  [dbo].[orders_dimen] C on A.Ord_id = C.Ord_id
JOIN  [dbo].[prod_dimens] D on A.Prod_id = D.Prod_id
JOIN  [dbo].[shipping_dimen] E on A.Ship_id = E.Ship_id) as newtable

SELECT *
FROM combined_table


--///////////////////////


--2. Find the top 3 customers who have the maximum count of orders.


SELECT TOP 3  
		  Cust_id
		, Customer_Name
		, count(Ord_id) count_orders
FROM combined_table
GROUP BY Cust_id
	   , Customer_Name
ORDER BY count_orders DESC



--/////////////////////////////////



--3.Create a new column at combined_table as DaysTakenForDelivery that contains the date difference of  and .
--Use "ALTER TABLE", "UPDATE" etc.

--select *, datediff(day,Order_Date,Ship_Date) DaysTakenForDelivery
--from combined_table
    
ALTER TABLE combined_table
ADD DaysTakenForDelivery İNT

UPDATE combined_table
SET DaysTakenForDelivery = DATEDIFF(DAY,Order_Date,Ship_Date)


--ALTER TABLE combined_table
--ADD [DaysTakenForDelivery] AS DATEDIFF (DAY,Order_Date,Ship_Date) PERSISTED

--////////////////////////////////////


--4. Find the customer whose order took the maximum time to get delivered.
--Use "MAX" or "TOP"


SELECT TOP 1 
		  Customer_Name 
		, DaysTakenForDelivery
FROM combined_table
ORDER BY DaysTakenForDelivery DESC

-----or 

SELECT Cust_id
	 , Customer_Name
	 , DaysTakenForDelivery
FROM combined_table
WHERE DaysTakenForDelivery = (
							SELECT MAX(DaysTakenForDelivery)
							FROM combined_table
							)


--////////////////////////////////



--5. Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011
--You can use date functions and subqueries


SELECT 
	  MONTH(order_date) month_of_2011
	, COUNT(DISTINCT Cust_id) count_of_cust
FROM combined_table
WHERE Cust_id in 
(
	SELECT DISTINCT 
		   Cust_id
	FROM combined_table
	WHERE MONTH(Order_Date) = 01 AND YEAR(Order_Date) = 2011
) 
AND	YEAR(Order_Date) = 2011
GROUP BY MONTH(order_date)

----------or


SELECT    MONTH(order_date) MONTH
		, COUNT(DISTINCT cust_id) Montly_Number_of_Customer
FROM	Combined_table A
WHERE EXISTS
			(
			SELECT  Cust_id
			FROM combined_table B
			WHERE YEAR (Order_Date) = 2011
			AND	MONTH (Order_Date) = 1
			AND A.Cust_id = B.Cust_id
			)
AND	YEAR(Order_Date) = 2011
GROUP BY MONTH(order_date)




--////////////////////////////////////////////


--6. write a query to return for each user acording to the time elapsed between the first purchasing and the third purchasing, 
--in ascending order by Customer ID
--Use "MIN" with Window Functions

SELECT	DISTINCT
		  Cust_id
		, Order_Date
		, Dense_number
		, FIRST_ORDER_DATE
		, DATEDIFF(DAY, FIRST_ORDER_DATE, Order_Date)
from
	(SELECT	
			Cust_id
			, ord_id
			, Order_Date
			, MIN (Order_Date) OVER (PARTITION BY cust_id) FIRST_ORDER_DATE
			, DENSE_RANK () OVER (PARTITION BY cust_id ORDER BY Order_date) Dense_number
	FROM	combined_table
	) A
	where A.Dense_number=3


	-----or -----------

WITH T1 AS 
(
SELECT  distinct
		Cust_id
	  , Ord_id
	  , Order_Date
	  , LEAD(Order_Date,2)  OVER (PARTITION by Cust_id ORDER BY Order_Date) next_purchasing
	  , RANK () OVER (PARTITION BY Cust_id ORDER BY Order_Date) row_num
	  , DATEDIFF(DAY, Order_Date, (LEAD(Order_Date,2)  OVER (PARTITION BY Cust_id ORDER BY Order_Date))) time_elapsed

FROM combined_table
)
SELECT 
		  *
FROM T1
WHERE row_num = 1 and time_elapsed is not null 


--//////////////////////////////////////

--7. Write a query that returns customers who purchased both product 11 and product 14, 
--as well as the ratio of these products to the total number of products purchased by all customers.
--Use CASE Expression, CTE, CAST and/or Aggregate Functions


;WITH CTE AS
(
SELECT 
			Cust_id
		  , SUM (CASE WHEN Prod_id=11 THEN Order_Quantity ELSE 0 END) Prod_11
		  , SUM (CASE WHEN Prod_id=14 THEN Order_Quantity ELSE 0 END) Prod_14
		  , sum (Order_Quantity) total_prod
FROM combined_table
GROUP BY Cust_id
HAVING 
	  SUM (CASE WHEN Prod_id=11 THEN Order_Quantity ELSE 0 END) > 0
  and SUM (CASE WHEN Prod_id=14 THEN Order_Quantity ELSE 0 END) > 0
)
SELECT
		 Cust_id
	   , total_prod
	   , Prod_11
	   , Prod_14
	   , CAST (1.0 * Prod_11 / total_prod AS NUMERIC (3,2)) AS ratio11
	   , CAST (1.0 * Prod_14 / total_prod AS NUMERIC (3,2)) AS ratio14
FROM CTE

--/////////////////



--CUSTOMER SEGMENTATION



--1. Create a view that keeps visit logs of customers on a monthly basis. (For each log, three field is kept: Cust_id, Year, Month)
--Use such date functions. Don't forget to call up columns you might need later.

CREATE VIEW CUSTOMER_LOGS AS
SELECT  
		cust_id
	  , YEAR(Order_Date) Year_of_visit
	  , MONTH(Order_Date) Month_of_visit
FROM combined_table


SELECT *
FROM CUSTOMER_LOGS
ORDER BY Cust_id



--//////////////////////////////////



  --2.Create a �view� that keeps the number of monthly visits by users. (Show separately all months from the beginning  business)
--Don't forget to call up columns you might need later.

CREATE VIEW NUMBER_VISIT AS
SELECT 
	  Cust_id	
	, YEAR(Order_Date) years
	, MONTH(Order_Date) months
	, COUNT(*) OVER (PARTITION BY Cust_id, YEAR(Order_Date), MONTH(Order_Date)) count_log
FROM combined_table


SELECT *
FROM NUMBER_VISIT
ORDER BY Cust_id


--//////////////////////////////////


--3. For each visit of customers, create the next month of the visit as a separate column.
--You can order the months using "DENSE_RANK" function.
--then create a new column for each month showing the next month using the order you have made above. (use "LEAD" function.)
--Don't forget to call up columns you might need later.

CREATE VIEW NEXT_VISIT
AS
SELECT *
		, LEAD (current_month,1) OVER (PARTITION BY Cust_id ORDER BY current_month) next_visit_month
FROM
(
SELECT   *
	   , DENSE_RANK () OVER (ORDER BY years, months) current_month      ----dense rank used due to reputation of entries
FROM NEXT_VISIT                                                      --------- above view used
) A;

SELECT *
FROM NEXT_VISIT

--/////////////////////////////////



--4. Calculate monthly time gap between two consecutive visits by each customer.
--Don't forget to call up columns you might need later.

CREATE VIEW TIME_GAPS
AS
SELECT   *
		, next_visit_month - current_month as time_gap
from NEXT_VISIT



SELECT * FROM TIME_GAPS

--///////////////////////////////////


--5.Categorise customers using average time gaps. Choose the most fitted labeling model for you.
--For example: 
--Labeled as �churn� if the customer hasn't made another purchase for the months since they made their first purchase.
--Labeled as �regular� if the customer has made a purchase every month.
--Etc.

;WITH T1 AS
(
SELECT 
		 Cust_id
	   , AVG(time_gap) avg_time_gap
FROM TIME_GAPS
group by Cust_id
)
select 
		 Cust_id
	   , case when avg_time_gap is null then 'churn'
			  when avg_time_gap = 1 then 'regular'
			  when avg_time_gap > 1 then 'iregular'
			  else 'unknown'
		 end as cust_category
from T1
			  
--/////////////////////////////////////

--MONTH-WISE RETENT�ON RATE


--Find month-by-month customer retention rate  since the start of the business.


--1. Find the number of customers retained month-wise. (You can use time gaps)
--Use Time Gaps


SELECT * FROM time_gaps


CREATE VIEW cnt_retained_customer
AS
SELECT  
		 *
       , COUNT (Cust_id) OVER (PARTITION BY next_visit_month) AS cnt_retained_cust
FROM time_gaps
WHERE time_gap = 1



CREATE VIEW cnt_total_customer
AS
SELECT  
		 *
       , count (Cust_id) OVER (PARTITION BY current_month) AS cnt_total_cust
FROM time_gaps
WHERE current_month > 1   ---- we dont choose first month because it is the first time they visited, we are looking for if there are another visits!



--//////////////////////


--2. Calculate the month-wise retention rate.

--Basic formula: o	Month-Wise Retention Rate = 1.0 * Number of Customers Retained in The Current Month / Total Number of Customers in the Current Month

--It is easier to divide the operations into parts rather than in a single ad-hoc query. It is recommended to use View. 
--You can also use CTE or Subquery if you want.

--You should pay attention to the join type and join columns between your views or tables.

WITH T1 AS
(
SELECT A.current_month, A.cnt_retained_cust, B.cnt_total_cust
FROM cnt_retained_customer A, cnt_total_customer B
WHERE A.current_month=B.current_month
)
SELECT DISTINCT 
		 current_month
		, CAST(1.0 *cnt_retained_cust*cnt_total_cust AS NUMERIC(3,2)) AS month_wise_retention
FROM T1
ORDER BY 1





---///////////////////////////////////
