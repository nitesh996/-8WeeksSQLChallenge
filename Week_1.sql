CREATE SCHEMA dannys_diner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
-----------------------------------------------------------------------------
select * from sales;
select * from menu;
select * from members;
--------------------------------------------------------------------------------
#Q1 What is the total amount each customer spent at the restaurant?
select a.customer_id, sum(b.price) as total_price
from sales a left join menu b on a. product_id=b.product_id
group by 1;

#Q2 How many days has each customer visited the restaurant?
select customer_id, count(distinct order_date) as days_visited
from sales
group by 1;

#Q3 What was the first item from the menu purchased by each customer?
select customer_id, order_date, product_id, product_name
from(
select a.customer_id, a.order_date, a.product_id, b.product_name, dense_rank() over(partition by a.customer_id 	order by a.order_date) as rankk
from sales a left join menu b on a.product_id=b.product_id
) as aaa
where aaa.rankk=1;

# Q4 What is the most purchased item on the menu and how many times was it purchased by all customers?
select customer_id, product_id, product_name, count_item 
from ( 
select a.customer_id, a.product_id, b.product_name, count(a.product_id) as count_item, dense_rank() over(partition by customer_id order by count(a.product_id) desc) as rankk
from sales as a left join menu as b on a.product_id= b.product_id
group by 1,2
order by 1,3 desc
) as aaa
where aaa.rankk=1;

# Q5 Which item was the most popular for each customer?
select customer_id, product_id, product_name, count_item 
from ( 
select a.customer_id, a.product_id, b.product_name, count(a.product_id) as count_item, dense_rank() over(partition by customer_id order by count(a.product_id) desc) as rankk
from sales as a left join menu as b on a.product_id= b.product_id
group by 1,2
order by 1,3 desc
) as aaa
where aaa.rankk=1;

# Q6 Which item was purchased first by the customer after they became a member?
select customer_id, order_date, product_id , product_name from (
select a.customer_id, a.order_date, a.product_id, b.product_name, dense_rank() over(partition by customer_id order by order_date) as rankk	
from sales a, menu b, members c
where a.product_id=b.product_id and a.customer_id= c.customer_id and a.order_date>=c.join_date
order by 1,2) as aaa
where aaa.rankk=1;

# Q7 Which item was purchased just before the customer became a member?
select customer_id, order_date, product_id , product_name from (
select a.customer_id, a.order_date, a.product_id, b.product_name, dense_rank() over(partition by customer_id order by order_date desc) as rankk	
from sales a, menu b, members c
where a.product_id=b.product_id and a.customer_id= c.customer_id and a.order_date<c.join_date
order by 1,2) as aaa
where aaa.rankk=1;

# Q8 What is the total items and amount spent for each member before they became a member?
with aa as(
select a.customer_id, a.order_date, b.join_date, a.product_id
from sales a left join members b on a.customer_id=b.customer_id
where a.order_date<b.join_date or b.join_date is null)
select a.customer_id, count(*) as count_orders, sum(b.price) as sum_price_spent
from aa a left join menu b on a.product_id=b.product_id
group by 1;

# Q9 If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select a.customer_id,
sum(case when a.product_id=1 then b.price*20 else b.price*10 end) as sum_points
from sales a left join menu b on a.product_id=b.product_id
group by 1;

# Q10 In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
select customer_id,
sum(case when aaa.order_date>=aaa.join_date and aaa.order_date<=aaa.valid_date then price*20 else price*10 end) as sum_points 
from (
select a.customer_id, a.order_date, a.product_id, b.product_name, b.price,c.join_date, c.join_date + interval 6 DAY as valid_date
from sales a, menu b, members c
where a.product_id=b.product_id and a.customer_id=c.customer_id and order_date<='2021-01-31') as aaa
group by 1
order by 1;
-------------------

select aaa.customer_id,
sum(case when aaa.order_date between aaa.join_date and aaa.valid_date then price*20 
     when product_name='sushi' then price*20 
	 else price*10 end) as sum_points 
from (
select a.customer_id, a.order_date, a.product_id, b.product_name, b.price,c.join_date, c.join_date + interval 6 DAY as valid_date
from sales a, menu b, members c
where a.product_id=b.product_id and a.customer_id=c.customer_id and order_date<='2021-01-31') as aaa
group by 1
order by 1;