/*
Objective: 
Analyze e-commerce transactional data using SQL to uncover insights related to revenue trends, customer behavior, product
performance, and operational efficiency.

Dataset contains:
Orders
Customers
Products
Payments
Order Items
*/


-- Joins after observing Tables
-- Query 1
select o.order_id, o.order_status, c.customer_city, c.customer_state
from orders o
join customers c on o.customer_id = c.customer_id
limit 10;

-- Query 2
select o.order_id, o.order_status, c.customer_state, p.payment_value
from orders o
join customers c on o.customer_id = c.customer_id
join order_payments p on p.order_id = o.order_id
limit 10;


-- KPI Queries
-- 1. Total Orders
select count(*) total_orders
from orders;

-- 2. Total Customers
select count(distinct(customer_id)) total_customers
from customers;

-- 3. Total Revenue
select round(sum(payment_value),2) total_revenue
from order_payments;

-- 4. Orders By Status
select order_status, count(order_status) total_orders
from orders
group by order_status
order by total_orders desc;

-- 5. Top States By Orders
select c.customer_state, count(customer_state) count_orders
from customers c
join orders o on c.customer_id = o.customer_id
group by c.customer_state
order by count_orders desc;

-- 6. Average Order Value
select round(avg(payment_value), 3) avg_odr_value
from order_payments;


-- Time-Based Sales Analysis
-- 1. Monthly Order Trend
select strftime('%Y-%m', order_purchase_timestamp) order_month, count(order_id) total_orders
from orders
group by strftime('%Y-%m', order_purchase_timestamp)
order by total_orders desc;

-- 2. Monthly Revenue Trend
select strftime('%Y-%m', o.order_purchase_timestamp) order_month, round(sum(p.payment_value), 2) total_revenue
from orders o
join order_payments p on p.order_id = o.order_id
group by strftime('%Y-%m', order_purchase_timestamp)
order by total_revenue desc;

-- 3. Top 10 Products By Revenue
select product_id, round(sum(price), 2) total_revenue
from order_items
group by product_id
order by total_revenue desc
limit 10;

-- 4. Top Product Categories
select p.product_category_name, round(sum(i.price), 2) total_revenue
from order_items i
join products p on p.product_id = i.product_id
group by p.product_category_name
order by total_revenue desc
limit 10;

-- 5. Average Delivery Time
select round(avg(julianday(order_delivered_customer_date) - julianday(order_purchase_timestamp)), 2) avg_delivery_days
from orders
where order_delivered_customer_date is not null

-- 6. States With Highest Revenue
select c.customer_state, round(sum(p.payment_value), 2) total_revenue
from customers c
join orders o on o.customer_id = c.customer_id
join order_payments p on p.order_id = o.order_id
group by c.customer_state
order by round(sum(p.payment_value), 2) desc
limit 10;


-- Advanced SQL Analytics
-- 1. Top Customers By Revenue
select c.customer_id, round(sum(p.payment_value), 2) total_revenue
from customers c
join orders o on o.customer_id = c.customer_id
join order_payments p on p.order_id = o.order_id
group by c.customer_id
order by round(sum(p.payment_value), 2) desc
limit 10;

-- 2. Find Repeat Customers
select c.customer_unique_id, count(o.customer_id) total_orders_placed
from orders o
join customers c on c.customer_id = o.customer_id
group by c.customer_unique_id
having count(o.customer_id) > 1
order by count(o.customer_id) desc;

-- 3. State Ranking based on Revenue Using Window Function
select customer_state,
total_revenue,
rank() over (order by total_revenue desc) state_rank
from
(
select c.customer_state, round(sum(p.payment_value), 2) total_revenue
from customers c
join orders o on o.customer_id = c.customer_id
join order_payments p on p.order_id = o.order_id
group by c.customer_state
) state_data;

-- 4. Running Revenue Total
select order_month,
total_revenue,
sum(total_revenue) over (order by order_month desc) running_total
from
(
select strftime('%Y-%m', o.order_purchase_timestamp) order_month, round(sum(p.payment_value), 2) total_revenue
from orders o
join order_payments p on p.order_id = o.order_id
group by strftime('%Y-%m', o.order_purchase_timestamp)
) month_data;

-- 5. Top Product Categories Per State
select customer_state,
product_category_name,
revenue
from
(
select c.customer_state,
p.product_category_name,
round(sum(i.price), 2) revenue,
rank() over (partition by c.customer_state order by sum(i.price) desc) rank_num
from orders o
join customers c on o.customer_id = c.customer_id
join order_items i on i.order_id = o.order_id
join products p on i.product_id = p.product_id
group by c.customer_state, p.product_category_name
) state_productCategory_data
where rank_num = 1
order by customer_state;


-- Data Cleaning + Professional SQL Structuring
-- SECTION 1 — NULL VALUE ANALYSIS
-- 1. Missing Delivery Dates
select count(*) missing_delivery_date
from orders
where order_delivered_customer_date is null;

-- 2. Missing Product Categories
select count(*) missing_product_category
from products
where product_category_name is null;

-- SECTION 2 — DUPLICATE CHECKS
-- 1. Duplicate Orders Check
select order_id, count(*) duplicate_orders
from orders
group by order_id
having count(*) > 1
order by order_id;

-- SECTION 3 — CASE WHEN
-- 1. Customer Segmentation
select customer_unique_id,
total_payment,
case
when total_payment > 1000 then 'high_value'
when total_payment > 500 then 'avg_value'
else 'low_value'
end as customer_segment
from
(
select c.customer_unique_id, round(sum(p.payment_value), 2) total_payment
from orders o
join customers c on o.customer_id = c.customer_id
join order_payments p on p.order_id = o.order_id
group by c.customer_unique_id
) segment
order by total_payment desc;

-- SECTION 4 — CTEs
-- 1. Revenue By State Using CTE
with state_revenue as
(
select c.customer_state, round(sum(p.payment_value) ,2) revenue
from orders o
join customers c on o.customer_id = c.customer_id
join order_payments p on o.order_id = p.order_id
group by c.customer_state
)
select *
from state_revenue
order by revenue desc;

-- SECTION 5 — Multi-CTE Analytical Query
-- 1. Revenue By Month using CTE and Rank
with
month_revenue as
(
select strftime('%Y-%m', o.order_purchase_timestamp) order_month,
round(sum(p.payment_value) ,2) revenue
from orders o
join order_payments p on o.order_id = p.order_id
group by strftime('%Y-%m', o.order_purchase_timestamp)
),
ranked_month as
(
select order_month, revenue,
rank() over (order by revenue desc) ranked_revenue
from month_revenue
)
select *
from ranked_month
order by ranked_revenue;


/*
Key Business Insights
This project demonstrates the use of SQL for business analytics, including KPI generation, customer analysis, revenue trend analysis, data
cleaning, and advanced analytical querying using window functions and CTEs.
Conclusion

1. Certain states contribute significantly higher revenue than others.
2. A small group of customers contributes disproportionately to sales.
3. Revenue shows clear monthly growth patterns.
4. Some product categories consistently outperform others.
5. Delivery delays may impact customer satisfaction and operational efficiency.
*/
