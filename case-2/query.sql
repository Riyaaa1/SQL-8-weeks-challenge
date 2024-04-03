/* This contains sql queries to clean the data and answer the questions.
Task for this study has been divided into four sub-sections. 
Some of the tables contain non-uniform datatypes and missing values along the different columns. */

DROP table if exists tasty_bytes_sample_data.pizza_runner.cleaned_runner_orders;
CREATE TEMPORARY TABLE tasty_bytes_sample_data.pizza_runner.cleaned_runner_orders AS(
    SELECT * 
    FROM tasty_bytes_sample_data.pizza_runner.runner_orders
);

-- replace the wrongly null text values with actual NULL
UPDATE tasty_bytes_sample_data.pizza_runner.cleaned_runner_orders SET pickup_time = NULL WHERE pickup_time = 'null';
UPDATE tasty_bytes_sample_data.pizza_runner.cleaned_runner_orders SET distance = NULL WHERE distance = 'null';
UPDATE tasty_bytes_sample_data.pizza_runner.cleaned_runner_orders SET duration = NULL WHERE duration = 'null';
UPDATE tasty_bytes_sample_data.pizza_runner.cleaned_runner_orders SET cancellation = NULL WHERE cancellation = 'null';


-- remove the inconsistent units in duration and distance columns
UPDATE tasty_bytes_sample_data.pizza_runner.cleaned_runner_orders SET duration = SUBSTRING(duration,1,2);
UPDATE tasty_bytes_sample_data.pizza_runner.cleaned_runner_orders SET distance = regexp_substr(distance,'\\d+(\\.\\d+)?');
DROP table if exists tasty_bytes_sample_data.pizza_runner.updated_customer_orders;
-- preprocessing customer_orders table
CREATE TEMPORARY TABLE tasty_bytes_sample_data.pizza_runner.updated_customer_orders AS(
    SELECT *
    FROM tasty_bytes_sample_data.pizza_runner.customer_orders);

-- replace 'null' with NULL values
UPDATE tasty_bytes_sample_data.pizza_runner.updated_customer_orders SET exclusions = NULL WHERE exclusions = 'null';
UPDATE tasty_bytes_sample_data.pizza_runner.updated_customer_orders SET extras = NULL WHERE extras = 'null';
UPDATE updated_customer_orders SET exclusions = NULL where exclusions = '';
UPDATE updated_customer_orders SET extras = NULL where extras = '';


/* questions
                                    A. PIZZA METRICS */

-- 1. How many pizzas were ordered?
SELECT COUNT(pizza_id)
FROM updated_customer_orders;

-- 2. How many unique customer orders were made?
SELECT COUNT(DISTINCT(customer_id))
FROM updated_customer_orders;

-- 3.How many successful orders were delivered by each runner?
SELECT runner_id, COUNT(order_id) as successful_orders
FROM cleaned_runner_orders
WHERE cancellation IS NULL OR
cancellation NOT IN ('Restaurant Cancellation','Customer Cancellation')
GROUP BY runner_id;

-- 4. How many of each type of pizza was delivered?
WITH successful_orders AS(
    SELECT order_id
    FROM cleaned_runner_orders
    WHERE cancellation IS NULL OR cancellation NOT IN ('Restaurant Cancellation','Customer Cancellation')
)
SELECT updated_customer_orders.pizza_id, pizza_names.pizza_name, COUNT(updated_customer_orders.pizza_id) AS number_of_orders
FROM updated_customer_orders
JOIN successful_orders ON updated_customer_orders.order_id = successful_orders.order_id
JOIN pizza_names ON updated_customer_orders.pizza_id = pizza_names.pizza_id
GROUP BY updated_customer_orders.pizza_id, pizza_names.pizza_name;
 
-- 5.How many Vegetarian and Meatlovers were ordered by each customer?
SELECT customer_id,
    COUNT(CASE WHEN pizza_id = 1 THEN 1 END) as Meatlovers,
    COUNT(CASE WHEN pizza_id = 2 THEN 1 END) as Vegetarian
FROM updated_customer_orders
GROUP BY customer_id;

-- 6. What was the maximum number of pizzas delivered in a single order?

WITH successful_orders AS(
    SELECT order_id
    FROM cleaned_runner_orders
    WHERE cancellation IS NULL OR cancellation NOT IN ('Restaurant Cancellation','Customer Cancellation')
)
SELECT MAX(pizza_count) AS max_pizza_delivered
FROM (
    SELECT updated_customer_orders.order_id, COUNT(updated_customer_orders.order_id) AS pizza_count
    FROM updated_customer_orders
    JOIN successful_orders
    ON updated_customer_orders.order_id = successful_orders.order_id
    GROUP BY updated_customer_orders.order_id
);

SELECT *
FROM updated_customer_orders
WHERE (exclusions IS NOT NULL) AND (extras IS NOT NULL);


-- 8.How many pizzas were delivered that had both exclusions and extras?
WITH delivered_orders AS
(SELECT order_id
FROM cleaned_runner_orders
WHERE cancellation IS NULL OR cancellation NOT IN ('Restaurant Cancellation','Customer Cancellation'))

SELECT uco.pizza_id, COUNT(uco.pizza_id) AS delivered_pizza_count
FROM updated_customer_orders AS uco 
RIGHT JOIN delivered_orders AS do
ON uco.order_id = do.order_id
WHERE (uco.exclusions IS NOT NULL) AND
(uco.extras IS NOT NULL)
GROUP BY uco.pizza_id;

/*9. What was the total volume of pizzas ordered for each hour of the day?

For a given hour, how many pizzas were ordered? one way to solve this would be to extract the hour part from the given 
order_time column in customer_orders table. Then, group that table by hour and count the pizza_id from that grouped table
# to extract the hour part of the order_time(timestamp datatype), use DATE_PART()

*/

SELECT DATE_PART('hour',order_time) as hour_of_day, COUNT(pizza_id) AS pizzas_ordered
FROM updated_customer_orders
GROUP BY hour_of_day
ORDER BY hour_of_day;


--10. What was the volume of orders for each day of the week?

SELECT TO_CHAR(order_time,'Dy') as day_of_Week, COUNT(pizza_id) as pizza_count
FROM updated_customer_orders
GROUP BY day_of_Week
ORDER BY pizza_count;


                                /* RUNNER AND CUSTOMER EXPERIENCE */


