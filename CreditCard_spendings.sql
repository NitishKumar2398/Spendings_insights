select * from public.credit_card_data

-- 1- write a query to print top 5 cities with highest spends and their percentage contribution 
-- of total credit card spends 

with cte as(
select city,sum(amount) as total_spends
from credit_card_data ccd group by city
order by total_spends desc limit 5),
cte2 as (
select sum(amount) as total_amount from credit_card_data ccd2)
select *, round(cast(total_spends as decimal) / total_amount * 100 ,2)
	as percentage_contribution
	from cte inner join cte2 on 1=1
	
-- 2- write a query to print highest spend month and amount spent in that month for each card type
	
with cte as (
select ccd."Card Type" ,extract(month from transaction_date) as month,
extract(year from transaction_date) as year,
sum(amount) as total_spend
from credit_card_data ccd 
group by ccd."Card Type",month,year
order by ccd."Card Type",total_spend desc)

select * from(select *, rank() over (partition by cte."Card Type" order by total_spend desc)
as rn from cte) a where rn =1

-- 3- write a query to print the transaction details(all columns from the table) for each card type when
-- it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)

with cte as (
select *,sum(amount) over (partition by ccd."Card Type" order by transaction_date,ccd."Transaction-id") 
as total_spend from credit_card_data ccd)

select * from (select *, rank() over (partition by cte."Card Type" order by total_spend) as rn from cte
where total_spend >= 1000000) a where rn=1

-- 4- write a query to find city which had lowest percentage spend for gold card type	
 
with cte as (
select city,ccd."Card Type", 
  sum(amount) as total_gold_amount
  from credit_card_data ccd 
  group by city, ccd."Card Type"
  having ccd."Card Type" ='Gold'),
cte2 as (
	select city,
	sum(amount) as trans_amount
    from credit_card_data ccd 
	group by city),
cte3 as (
	select cte.city,
	cte.total_gold_amount,
	cte2.trans_amount,
    round(cast(cte.total_gold_amount as decimal) / cte2.trans_amount * 100,2) as pct_contribution
    from cte inner join cte2 on cte.city = cte2.city)
select city,pct_contribution from cte3
order by pct_contribution limit 1

-- 5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type 
-- (example format : Delhi , bills, Fuel)

with cte as
(select city, 
 ccd."Exp Type", sum(amount) as total_amount 
 from credit_card_data ccd 
 group by city, ccd."Exp Type"),
 cte2 as 
 (select city, 
	 max(total_amount)  as highest_expense,
     min(total_amount) as lowest_expense 
	 from cte group by city)
select cte.city,
   max(case when total_amount = highest_expense then cte."Exp Type" end) as highest_expense_type,
   min(case when total_amount = lowest_expense then cte."Exp Type" end) as lowest_expense_type
   from cte
   inner join cte2 on cte.city= cte2.city
   group by cte.city
   order by cte.city
   
 -- 6- write a query to find percentage contribution of spends by females for each expense type
  
with cte as(
select ccd."Exp Type", sum(amount) as total 
from credit_card_data ccd 
where gender='F'
group by ccd."Exp Type"),
cte2 as (
select ccd."Exp Type", sum(amount) as total_amount
from credit_card_data ccd  
group by ccd."Exp Type")
select cte."Exp Type",--cte.total,
--cte2.total_amount, 
round(cast(cte.total as decimal)/cte2.total_amount * 100,2) as
percentage_spends from cte
inner join cte2 on
cte."Exp Type" = cte2."Exp Type" 
order by percentage_spends desc 

Alternate_approach_for_query_7

select "Exp Type",round(cast(sum(case when gender='F' then amount else 0 end) as decimal)/sum(amount)*100,2) 
as percentage_contribution
from credit_card_data ccd 
group by "Exp Type" 
order by percentage_contribution desc

-- 7- Which card and expense type combination saw highest month over month growth in Jan-2014

with cte as (
	select 
	ccd."Card Type", 
	ccd."Exp Type" , 
	Extract(month from transaction_date) as spend_month, 
	Extract(year from transaction_date) as spend_year,
	sum(amount) as spend
	from credit_card_data ccd
	Group By ccd."Card Type", ccd."Exp Type", 
	spend_month, spend_year),
	cte2 as (
	select *, lag(spend,1)over(partition by cte."Card Type", cte."Exp Type" 
	order by spend_year, spend_month) as lag_spend
	from cte)	
select *, round(cast((spend-lag_spend) as decimal)/lag_spend*100,2) as pct_growth
from cte2 where spend_month = 1 and spend_year = 2014 and lag_spend is not null and (spend-lag_spend)>0 
order by pct_growth desc limit 3

-- 8- during weekends which city has highest total spend to total no of transcations ratio 

select city,
--sum(amount) as total,
--count(1) as total_no_of_trans,
sum(amount) / count(1) as ratio
from credit_card_data ccd 
where extract(DOW from ccd.transaction_date) in('6','0')
group by city
order by ratio desc limit 1

-- 9- which city took least number of days to reach its 500th transaction after the first 
-- transaction in that city

with cte as (
select *,row_number() over (partition by city order by transaction_date, ccd."Transaction-id") as rn
from credit_card_data ccd)

select city,min(cte.transaction_date) as start_date,max(cte.transaction_date) as fivehund_transaction_date,
(max(transaction_date)-min(transaction_date)) as no_of_days_took
from cte
where rn=1 or rn=500
group by city
having count(*)=2
order by no_of_days_took 
limit 1
