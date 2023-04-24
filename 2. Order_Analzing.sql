drop table #shipping
select 
*
,(case
	when shipping_fee = 0 then 'freeship'
	when shipping_fee <=10000 	then  '<= 10000'
	when shipping_fee <=20000 and shipping_fee > 10000	then  '<= 20000'
	when shipping_fee <=30000 and shipping_fee > 20000	then  '<= 30000'
	when shipping_fee <=40000 and shipping_fee > 30000	then  '<= 40000'
	when shipping_fee <=50000 and shipping_fee > 40000	then  '<= 50000'
	else '> 50000'
end) as shipping_fee_range
into #shipping
from
[dbo].[order_data]
-- ANALYZING SHIPPING FEE
-- 1. Shipping Contribution
-- select count(1) from #shipping -- total # of orders = 61728 orders
select
shipping_fee_range
,count (1) as #_of_orders
,count (1)/61728.00 as contribution
from
#shipping 
group by
shipping_fee_range
order by
shipping_fee_range
-- 2. Cancel rate by shipping fee 
with 
cancel as (
select
shipping_fee_range
,count (1) as #_of_canceled_orders
from #shipping
where order_status = 'cancelled'
group by shipping_fee_range),
total as (
select
shipping_fee_range
,count (1) as #_of_orders
from #shipping
group by shipping_fee_range)
select
a.shipping_fee_range
,#_of_canceled_orders
,#_of_orders
,cast (#_of_canceled_orders as float)/#_of_orders as cancel_rate
from
total a
left join
cancel b
on
a.shipping_fee_range = b.shipping_fee_range
order by
cancel_rate
--ANALYZING SELLING_PRICE,PROMOTION
drop table #price
with cte as(
select
[customer_unique_id]
,[order_id]
,[item_quantity]
,[onsite_original_price]
,[selling_price]
,[selling_price]/[item_quantity] as avg_price
,order_status
from
[dbo].[order_data])
select 
*,
(case
	when avg_price <= 100000 then '<= 100,000'
	when avg_price <= 300000 and avg_price > 100000	  then '<= 300,000'
	when avg_price <= 500000 and avg_price > 300000	  then '<= 500,000'
	when avg_price <= 1000000 and avg_price > 500000  then '<= 1,000,000'
	else '> 1,000,000'
end) as price_range
into #price
from cte
--------------------------------------------------------------
-- 1. Price Segment
select
price_range
,count (1) as #_of_orders
from 
#price
group by
price_range
order by
price_range
-- 2. Cancel rate by price segment
with 
cancel as (
select
price_range
,count (1) as #_of_canceled_orders
from #price
where order_status = 'cancelled'
group by price_range),
total as (
select
price_range
,count (1) as #_of_orders
from #price
group by price_range)
select
a.price_range
,#_of_canceled_orders
,#_of_orders
,cast (#_of_canceled_orders as float)/#_of_orders as cancel_rate
from
total a
left join
cancel b
on
a.price_range = b.price_range
order by
cancel_rate
--------------------------------------------------------------
-- ANALZING PAYMENT METHODs
-- 1. payment method's contribution
select
[payment_method]
,count (1) as #_of_orders
from 
[dbo].[order_data]
group by
[payment_method]
order by
[payment_method]
-- 2. cancel rate by payment method
with 
cancel as (
select
payment_method
,count (1) as #_of_canceled_orders
from [dbo].[order_data]
where order_status = 'cancelled'
group by payment_method),
total as (
select
payment_method
,count (1) as #_of_orders
from [dbo].[order_data]
group by payment_method)
select
a.payment_method
,#_of_canceled_orders
,#_of_orders
,cast (#_of_canceled_orders as float)/#_of_orders as cancel_rate
from
total a
left join
cancel b
on
a.payment_method = b.payment_method
order by
cancel_rate
----------------------------------------------------------------
-- ANALYZING ORDER BY DATE
-- Cancel rate/orders/cancelled order by date
with 
cancel as (
select
created_day
,count (1) as #_of_canceled_orders
from [dbo].[order_data]
where order_status = 'cancelled'
group by created_day),
total as (
select
created_day
,count (1) as #_of_orders
from [dbo].[order_data]
group by created_day)
select
a.created_day
,#_of_canceled_orders
,#_of_orders
,cast (#_of_canceled_orders as float)/#_of_orders as cancel_rate
from
total a
left join
cancel b
on
a.created_day = b.created_day
order by
cancel_rate
----------------------------------------------------------------
-- ANALYZING DISCOUNT RATE
drop table #discount
with cte as (
select 
*,
1-selling_price*1.00/onsite_original_price as discount_rate
from #price)
select 
*
,(case
	when discount_rate = 0 then 'no discount'
	when discount_rate <= 10.00/100 and discount_rate >	0		then '<= 10%'
	when discount_rate <= 20.00/100 and discount_rate >	10.00/100	then '<= 20%'
	when discount_rate <= 30.00/100 and discount_rate >	20.00/100	then '<= 30%'
	when discount_rate <= 40.00/100 and discount_rate >	30.00/100	then '<= 40%'
	when discount_rate <= 50.00/100 and discount_rate >	40.00/100	then '<= 50%'
	when discount_rate <= 60.00/100 and discount_rate >	50.00/100	then '<= 60%'
	when discount_rate <= 70.00/100 and discount_rate >	60.00/100	then '<= 70%'
	when discount_rate <= 80.00/100 and discount_rate >	70.00/100	then '<= 80%'
	when discount_rate <= 90.00/100 and discount_rate >	80.00/100	then '<= 90%'
	when discount_rate < 100.00/100 and discount_rate >	90.00/100	then '< 100%'
	else '100%'
end) as discount_range
into #discount
from
cte
-- 1. Discount segment
select
discount_range
,price_range
,count (1) as #_of_orders
,sum (selling_price) as total_amount
from 
#discount
group by
discount_range
,price_range
order by
discount_range
,price_range
-- 2. cancel rate by discount
with 
cancel as (
select
discount_range
,count (1) as #_of_canceled_orders
from #discount
where order_status = 'cancelled'
group by discount_range),
total as (
select
discount_range
,count (1) as #_of_orders
from #discount
group by discount_range)
select
a.discount_range
,#_of_canceled_orders
,#_of_orders
,cast (#_of_canceled_orders as float)/#_of_orders as cancel_rate
from
total a
left join
cancel b
on
a.discount_range = b.discount_range
order by
cancel_rate
-- discount 20/30/40/50 breakdown
select * from  #d