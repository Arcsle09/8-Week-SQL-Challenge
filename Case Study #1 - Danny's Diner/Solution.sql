/****** What is the total amount each customer spent at the restaurant ? *******/
select customer_id customer,sum(m.price) total_amount from sales s inner join menu m on s.product_id = m.product_id
group by customer_id;

/***** How many days has each customer visited the restaurant ? ******/
select customer_id customer,count(distinct(order_date)) no_of_visits from sales group by customer_id;

/****** What was the first item from the menu purchased by each customer? *****/
with first_order_tbl as (select customer_id,
		order_date,
		product_id,
        min(order_date) over (partition by customer_id) 'first_order_date'
        from sales),
first_product_order as (
select customer_id,order_date,product_id from first_order_tbl where order_date=first_order_date),
rank_first_order_tbl as (
select customer_id,order_date,product_id,row_number() over (partition by customer_id) 'rnk' from first_product_order)
select rf.customer_id customer_id,product_name first_item_purchased from rank_first_order_tbl rf inner join menu m on rf.product_id=m.product_id where rnk=1;

/****** What is the most purchased item on the menu and how many times was it purchased by all customers? *****/
select m.product_name product_name,s.product_count 'Most_Purchased_Item' from (
select distinct product_id,count(product_id) over (partition by product_id) as product_count from sales
order by count(product_id) over (partition by product_id)) s
inner join menu m on s.product_id=m.product_id order by product_count desc limit 1;

/****** Which item was the most popular for each customer? ******/
with count_product_cust_tbl as (
select customer_id,product_id,count(product_id) as 'product_count' from sales group by customer_id,product_id),
most_popular_items as (
select distinct customer_id,m.product_name product_name,product_count,max(product_count) over (partition by customer_id) most_popular from count_product_cust_tbl cp inner join menu m on cp.product_id = m.product_id)
select customer_id,product_name from most_popular_items where product_count = most_popular;

/****** Which item was purchased first by the customer after they became a member? ******/
with items_post_membership as (
select s.customer_id customer_id,s.order_date order_date,s.product_id product_id from sales s inner join members m on s.customer_id = m.customer_id and order_date>join_date order by s.order_date),
first_purch_post_membrsp as (
select pm.*,m.product_name product_name,row_number() over (partition by customer_id) 'first_purch_date' from items_post_membership pm left join menu m on pm.product_id = m.product_id)
select customer_id,product_name from first_purch_post_membrsp where first_purch_date=1;

/****** Which item was purchased just before the customer became a member? ******/
with items_pre_membership as (
select s.customer_id customer_id,s.order_date order_date,s.product_id product_id from sales s inner join members m on s.customer_id = m.customer_id and order_date<join_date order by s.order_date,s.product_id desc),
first_purch_post_membrsp as (
select pm.*,m.product_name product_name,row_number() over (partition by customer_id) 'last_purch_date' from items_pre_membership pm left join menu m on pm.product_id = m.product_id)
select customer_id,product_name from first_purch_post_membrsp where last_purch_date=1;

/****** What is the total items and amount spent for each member before they became a member? *****/
with sm as (select m.customer_id Mem,s.product_id product_id 
from members m inner join sales s 
on m.customer_id=s.customer_id 
where m.join_date > s.order_date)
select sm.Mem,count(sm.product_id) Num_of_Products,sum(me.price) Total_Amount_Spent from sm inner join menu me on sm.product_id=me.product_id
group by sm.Mem;

/***** If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have? ****/
select customer_id,
sum(case when product_name='sushi' then price*10*2 else price*10 end) as total_points_per_customer 
from menu me inner join sales s on me.product_id=s.product_id group by customer_id;

/***** In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January? ****/
select ms.customer_id customer_id,sum(price*10*2) total_points_jan from (select s.customer_id customer_id, 
s.product_id product_id,s.order_date order_date
from sales s inner join members m on s.customer_id=m.customer_id and m.join_date<=s.order_date) ms
inner join menu me on ms.product_id=me.product_id where order_date <= '2021-01-31' group by ms.customer_id;
