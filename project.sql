--customers table contains customers data
SELECT * from customers limit 5

--employees table contains all employees information
SELECT * from employees limit 5

--offices table contains sales office information
select * from offices limit 5

--orders table contains customer's sales orders 
SELECT * from orders LIMIT 5

--ordersdetails table contains sales order line for each sales order
SELECT * from orderdetails LIMIT 5

--payments table contains customers' payment records
SELECT * from payments LIMIT 5

--products table contains a list of scale model cars
SELECT * from products LIMIT 5

--productlines contains a list of product line categories
SELECT * from productlines LIMIT 5

---------------------------------------------------------------

--use PRAGMA statements in sqlite to get info about table  

PRAGMA table_info(products) ;

--query to get table names, no. of attributes and rows 

SELECT 'products'  as tablename,count() as number_of_attributes,
(select count(*) from products )as number_of_rows
FROM PRAGMA_TABLE_INFO('products')
union 
SELECT 'customers'  as tablename,count() as number_of_attributes,
(select count(*) from customers )as number_of_rows
FROM PRAGMA_TABLE_INFO('customers')
union 
SELECT 'productlinesines'  as tablename,count() as number_of_attributes,
(select count(*) from productlines )as number_of_rows
FROM PRAGMA_TABLE_INFO('productlines')
union 
SELECT 'orders'  as tablename,count() as number_of_attributes,
(select count(*) from orders )as number_of_rows
FROM PRAGMA_TABLE_INFO('orders')
union 
SELECT 'orderdetails'  as tablename,count() as number_of_attributes,
(select count(*) from orderdetails )as number_of_rows
FROM PRAGMA_TABLE_INFO('orderdetails')
union 
SELECT 'payments'  as tablename,count() as number_of_attributes,
(select count(*) from payments )as number_of_rows
FROM PRAGMA_TABLE_INFO('payments')
union 
SELECT 'employees'  as tablename,count() as number_of_attributes,
(select count(*) from employees )as number_of_rows
FROM PRAGMA_TABLE_INFO('employees')
union 
SELECT 'offices'  as tablename,count() as number_of_attributes,
(select count(*) from offices )as number_of_rows
FROM PRAGMA_TABLE_INFO('offices');


--Question 1: Which Products Should We Order More of or Less of?

with cte as (
select productName,p.productCode,MSRP,quantityInStock,sum(quantityOrdered) as total_orders
from products p
inner join orderdetails  od
on p.productCode=od.productCode
GROUP by p.productCode
order by quantityInStock 
limit 10)

SELECT productName,productCode, round(1.0*total_orders/quantityInStock,2) as low_stock,
total_orders*MSRP as product_performance
from cte 
GROUP by productCode
order by product_performance  desc,low_stock 

--Question 2: How Should We Match Marketing and Communication Strategies to Customer Behavior?
--Finding the VIP and Less Engaged Customers
with profits as(
select customerNumber,sum(quantityOrdered*(priceEach-buyPrice)) as profit
from products p
inner join orderdetails od 
on p.productCode=od.productCode
inner join orders odr
on od.orderNumber=odr.orderNumber
GROUP by customerNumber
)
--top VIP customers
select contactLastName,contactFirstName,city,country,'VIP' as note
from customers c 
where customerNumber in (select customerNumber from profits  order by profit desc limit 5)
union
--least engaged customers 
select contactLastName,contactFirstName,city,country,'Least engaged' as note
from customers c 
where customerNumber in (select customerNumber from profits  order by profit asc  limit 5)

--Question 3: How Much Can We Spend on Acquiring New Customers?

--Before that let's find out no. of new customers arrinving every month
with  payment_with_year_month_table as (
SELECT *, 
       CAST(SUBSTR(paymentDate, 1,4) AS INTEGER)*100 + CAST(SUBSTR(paymentDate, 6,7) AS INTEGER) AS year_month
  FROM payments p),
customers_by_month_table as(  
  SELECT p1.year_month, COUNT(*) AS number_of_customers, SUM(p1.amount) AS total
  FROM payment_with_year_month_table p1
 GROUP BY p1.year_month),
 new_customers_by_month_table as(
 SELECT p1.year_month, 
       COUNT(DISTINCT customerNumber) AS number_of_new_customers,
       SUM(p1.amount) AS new_customer_total,
       (SELECT number_of_customers
          FROM customers_by_month_table c
        WHERE c.year_month = p1.year_month) AS number_of_customers,
       (SELECT total
          FROM customers_by_month_table c
         WHERE c.year_month = p1.year_month) AS total
  FROM payment_with_year_month_table p1
 WHERE p1.customerNumber NOT IN (SELECT customerNumber
                                   FROM payment_with_year_month_table p2
                                  WHERE p2.year_month < p1.year_month)
 GROUP BY p1.year_month)
 
 SELECT year_month, 
       ROUND(number_of_new_customers*100/number_of_customers,1) AS number_of_new_customers_props,
       ROUND(new_customer_total*100/total,1) AS new_customers_total_props
  FROM new_customers_by_month_table;
 
 
  --To determine how much money we can spend acquiring new customers, we can compute the Customer Lifetime Value (LTV), 
 --which represents the average amount of money a customer generates
  --query to compute the average of customer profits
with profits as(
select customerNumber,sum(quantityOrdered*(priceEach-buyPrice)) as profit
from products p
inner join orderdetails od 
on p.productCode=od.productCode
inner join orders odr
on od.orderNumber=odr.orderNumber
GROUP by customerNumber
)  
select round(avg(profit),2) as LTV
from profits
  
  