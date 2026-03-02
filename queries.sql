/* Task_1 : Provide the list of markets in which
			Customer "AtliQ Exclusive" operates its bussiness in the APAC region*/

SELECT 
    market
FROM
    dim_customer
WHERE
    customer LIKE '%Atliq Exclusive%'
        AND region LIKE '%APAC%';
        
/* Task_2 : What is the percentage of unique product increase in 2021 vs 2020?
			The final output contains these fields,
				Unique_Products_2020
				Unique_Products_2021
				Percentage_change*/
WITH product_count AS (SELECT 
    fiscal_year, COUNT(DISTINCT product_code) AS unique_products
FROM
    fact_sales_monthly
WHERE
    fiscal_year IN (2020 , 2021)
GROUP BY fiscal_year)
SELECT  max(CASE 
			WHEN fiscal_year=2020 then unique_products end) as unique_products_2020,
		max(CASE 
			WHEN fiscal_year=2021 then unique_products end) as unique_products_2021,
		ROUND((max(CASE WHEN fiscal_year=2021 then unique_products end)
			-max(CASE WHEN fiscal_year=2020 then unique_products end))*100
            /max(CASE WHEN fiscal_year=2020 then unique_products end),2) AS Percentage_change
FROM Product_count;

/* Task_3 : Provide a report with all the unique product counts for each  segment  and 
			sort them in descending order of product counts. The final output contains 2 fields, 
				segment 
				product_count */

SELECT 
    segment, COUNT(DISTINCT product_code) AS product_count
FROM
    dim_product
GROUP BY segment
ORDER BY product_count DESC;

/* Task_4 : Follow-up: Which segment had the most increase in unique products in 2021 vs 2020?
			The final output contains these fields, 
				segment 
				product_count_2020 
				product_count_2021 
				difference */

SELECT 
    segment,
    product_count_2020,
    product_count_2021,
    (product_count_2021 - product_count_2020) AS difference
FROM
    (SELECT 
        segment, COUNT(DISTINCT product_code) AS product_count_2020
    FROM
        dim_product
    JOIN fact_sales_monthly USING (product_code)
    WHERE
        fiscal_year = 2020
    GROUP BY segment) AS pc20
        JOIN
    (SELECT 
        segment, COUNT(DISTINCT product_code) AS product_count_2021
    FROM
        dim_product
    JOIN fact_sales_monthly USING (product_code)
    WHERE
        fiscal_year = 2021
    GROUP BY segment) AS pc21 USING (segment);

/* Task 5 :  Get the products that have the highest and lowest manufacturing costs. 
			 The final output should contain these fields, 
				product_code 
				product 
				manufacturing_cost*/

SELECT 
    product_code, product, manufacturing_cost
FROM
    dim_product
        JOIN
    fact_manufacturing_cost USING (product_code)
WHERE
    manufacturing_cost IN ((SELECT 
            MAX(manufacturing_cost)
        FROM
            fact_manufacturing_cost) , (SELECT 
                MIN(manufacturing_cost)
            FROM
                fact_manufacturing_cost))
ORDER BY manufacturing_cost DESC;

/* Task 6 : Generate a report which contains the top 5 customers who received an 
			average high  pre_invoice_discount_pct  for the  fiscal  year 2021  and in the 
			Indian  market. The final output contains these fields, 
				customer_code 
				customer 
				average_discount_percentage */
SELECT 
    customer_code,
    customer,
    ROUND(AVG(pre_invoice_discount_pct), 2) AS average_discount_percentage
FROM
    dim_customer
        JOIN
    fact_pre_invoice_deductions USING (customer_code)
WHERE
    fiscal_year = 2021 AND market = 'India'
GROUP BY customer_code,customer
ORDER BY average_discount_percentage DESC
limit 5;

/* Task 7 : Get the complete report of the Gross sales amount for the customer  “Atliq Exclusive”  for each month.  
			This analysis helps to  get an idea of low and high-performing months and take strategic decisions. 
			The final report contains these columns: 
				Month 
				Year 
				Gross sales Amount */

SELECT 
    s.date,
    s.fiscal_year,
    ROUND(SUM(s.sold_quantity * g.gross_price), 2) AS Gross_sales_amount
FROM
    fact_sales_monthly s
        JOIN
    fact_gross_price g ON s.product_code = g.product_code
        AND s.fiscal_year = g.fiscal_year
        JOIN
    dim_customer c ON s.customer_code = c.customer_code
WHERE
    customer = 'Atliq Exclusive'
GROUP BY s.date , s.fiscal_year
ORDER BY Gross_sales_amount DESC;

/* Task 8 : In which quarter of 2020, got the maximum total_sold_quantity? The final 
			output contains these fields sorted by the total_sold_quantity, 
				Quarter, 
				total_sold_quantity */

with CTE1 AS 
(SELECT 
	date,
    fiscal_year,
    (CASE
		WHEN month(date) in (9, 10, 11) then "Q1"
        WHEN month(date) in (12,1,2) then "Q2"
        WHEN month(date) in (3,4,5) then "Q3"
        ELSE "Q4"
	END) as quarter,sum(sold_quantity) AS sold_quantity
		FROM fact_sales_monthly
		GROUP BY date, quarter,fiscal_year )
SELECT quarter, sum(sold_quantity) as total_sold_quantity from CTE1
		WHERE fiscal_year=2020
		GROUP BY quarter
		ORDER BY total_sold_quantity desc
limit 1;

/* Task 9 : Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
			The final output  contains these fields, 
				channel 
				gross_sales_mln 
				percentage */

SELECT *,
		Round(gross_sales_mln*100/sum(gross_sales_mln)over(),2) as pct from
(SELECT 
    c.channel,
    Round(SUM(s.sold_quantity * g.gross_price) / 1000000,2) AS Gross_sales_mln
FROM
    fact_sales_monthly s
        JOIN
    fact_gross_price g ON s.product_code = g.product_code
        AND s.fiscal_year = g.fiscal_year
        JOIN
    dim_customer c ON s.customer_code = c.customer_code
WHERE
    s.fiscal_year = 2021
GROUP BY c.channel) as Total_Gross_sales
ORDER BY pct DESC
limit 1;

/* Task 10 : Get the Top 3 products in each division that have a high 
			total_sold_quantity in the fiscal_year 2021? The final output contains these fields, 
				division 
				product_code 
				product 
				total_sold_quantity 
				rank_order */

WITH CTE2 AS 
(select *,
	dense_rank() 
	OVER(partition by division order by total_sold_qty DESC) as rnk
FROM
(SELECT 
    p.division,
    p.product_code,
    p.product,
    sum(s.sold_quantity) as Total_sold_qty
FROM
    dim_product p
        JOIN
    fact_sales_monthly s ON p.product_code = s.product_code
WHERE
    s.fiscal_year = 2021
    GROUP BY p.division, p.product_code, p.product) t)
select * from CTE2
where rnk<=3;
