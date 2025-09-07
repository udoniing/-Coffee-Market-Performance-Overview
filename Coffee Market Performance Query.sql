-- Key Questions
-- Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?
SELECT 
	city_name,
	ROUND(population * 0.25 / 1000000, 2) AS population_25p_in,
	city_rank
FROM city
ORDER BY city_rank


-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
SELECT
	SUM(total) as revenue
FROM sales
WHERE EXTRACT (YEAR FROM sale_date) = 2023 AND EXTRACT (QUARTER FROM sale_date) = 4

SELECT
	ci.city_name,
	SUM(s.total) as revenue
FROM sales as s
JOIN customers as cu
ON s.customer_id = cu.customer_id
JOIN city as ci
ON cu.city_id = ci.city_id
WHERE 
	EXTRACT (YEAR FROM s.sale_date) = 2023
	AND EXTRACT (QUARTER FROM s.sale_date) = 4
GROUP BY city_name


-- Sales Count for Each Product
-- How many units of each coffee product have been sold?
SELECT 
	s.product_id,
	p.product_name,
	COUNT(s.product_id) as units_sold
FROM sales as s 
JOIN products as p
ON s.product_id = p.product_id
GROUP BY s.product_id, p.product_name
ORDER BY s.product_id 

-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?
SELECT
	ci.city_name,
	ROUND(SUM(s.total::NUMERIC) / COUNT(s.customer_id::NUMERIC), 2) AS average_sales_per_customer
FROM sales as s
JOIN customers as cu
ON s.customer_id = cu.customer_id
JOIN city as ci
ON cu.city_id = ci.city_id
GROUP BY ci.city_name


-- City Population and Coffee Consumers
-- Provide a list of cities along with their populations and estimated coffee consumers.
SELECT 
	city_name,
	ROUND(population/1000000, 2) AS population_in_millions,
	ROUND(population * 0.25 / 1000000, 2) AS population_25p_in_millions
FROM city
	

-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?
WITH product_sales AS (
    SELECT
        ci.city_name,
        p.product_name,
		COUNT(s.product_id),
        DENSE_RANK() OVER (
            PARTITION BY ci.city_name 
            ORDER BY COUNT(s.product_id) DESC
        ) AS rank_in_city
    FROM sales AS s
    JOIN products AS p
        ON s.product_id = p.product_id
    JOIN customers AS cu
        ON cu.customer_id = s.customer_id
    JOIN city AS ci
        ON ci.city_id = cu.city_id
    GROUP BY ci.city_name, p.product_name
)
SELECT
    *
FROM product_sales
WHERE rank_in_city <= 3;


-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?
SELECT
	ci.city_name,
	COUNT (DISTINCT s.customer_id) AS unique_customer
FROM sales as s
JOIN customers as cu
ON s.customer_id = cu.customer_id
JOIN city as ci
ON cu.city_id = ci.city_id
GROUP BY ci.city_name


-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer
WITH avg_sales_rent AS (
    SELECT
        ci.city_name,
       	ROUND(SUM(s.total)::NUMERIC / COUNT (DISTINCT s.customer_id)::NUMERIC, 2) AS avg_revenue,
		ROUND(ci.estimated_rent::NUMERIC / COUNT (DISTINCT s.customer_id)::NUMERIC, 2) as avg_rent
    FROM sales as s
	JOIN customers as cu
	ON s.customer_id = cu.customer_id
	JOIN city as ci
	ON cu.city_id = ci.city_id
    GROUP BY ci.city_name, ci.estimated_rent
)

SELECT *
FROM avg_sales_rent


-- Market Potential Analysis
-- Identify the top 3 cities based on the highest sales, return city name, total sales, total rent, total customers, estimated coffee consumers
SELECT
	ci.city_name,
	SUM(s.total) as total_revenue,
	ci.estimated_rent as total_rent,
	COUNT (DISTINCT s.customer_id) AS total_customer,
	ROUND(ci.population * 0.25 / 1000000, 2) AS population_25p_in_M,
	ROUND(SUM(s.total)::NUMERIC / COUNT (DISTINCT s.customer_id)::NUMERIC, 2) AS avg_revenue,
	ROUND(ci.estimated_rent::NUMERIC / COUNT (DISTINCT s.customer_id)::NUMERIC, 2) as avg_rent
FROM sales AS s
JOIN products AS p
        ON s.product_id = p.product_id
    JOIN customers AS cu
        ON cu.customer_id = s.customer_id
    JOIN city AS ci
        ON ci.city_id = cu.city_id
GROUP BY ci.city_name, ci.estimated_rent, ci.population
ORDER BY total_revenue DESC