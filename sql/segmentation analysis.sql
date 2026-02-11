-- Роблю правильні типи даних

alter table dbo.online_retail_SQl
alter column Quantity int

alter table dbo.online_retail_SQl
alter column Price float

alter table dbo.online_retail_SQl
alter column InvoiceDate datetime2

select top 10
Quantity,
Price,
(Quantity * Price) as TotalPrice
from dbo.online_retail_SQl
order by Quantity desc


-- Початок сегментації

select
Customer_ID,
max(InvoiceDate)as Last_Purchase_Date,
count(distinct Invoice) as Total_Orders,
sum(Quantity * Price) as Total_Spend
from dbo.online_retail_SQl
where Customer_id is not null
group by Customer_ID


-- Огляд даних за допомогою агрегатних функцій

with agg_columns as (
	select
	Customer_ID,
	max(InvoiceDate)as Last_Purchase_Date,
	count(distinct Invoice) as Total_Orders,
	sum(Quantity * Price) as Total_Spend
	from dbo.online_retail_SQl
	where Customer_id is not null
	group by Customer_ID
)
select
min(Total_Orders) as min_to,
max(Total_Orders) as max_to,
avg(Total_orders) as avg_to,
min(Total_spend) as min_ts,
max(Total_spend) as max_ts,
avg(Total_Spend) as avg_ts
from agg_columns


-- Огляд даних щоб зрозуміти розкид

with prc_columns as (
	select
	Customer_ID,
	datediff(day, max(InvoiceDate), (select max(InvoiceDate) from dbo.online_retail_sql)) as recent_days_count,
	count(distinct Invoice) as Total_Orders,
	sum(Quantity * Price) as Total_Spend
	from dbo.online_retail_SQl
	where Customer_id is not null
	group by Customer_ID
)
select distinct
percentile_disc(0.2) within group(order by recent_days_count) over() as prc_20_rd,
percentile_disc(0.4) within group(order by recent_days_count) over() as prc_40_rd,
percentile_disc(0.6) within group(order by recent_days_count) over() as prc_60_rd,
percentile_disc(0.8) within group(order by recent_days_count) over() as prc_80_rd,

percentile_disc(0.2) within group(order by Total_Orders) over() as prc_20_to,
percentile_disc(0.4) within group(order by Total_Orders) over() as prc_40_to,
percentile_disc(0.6) within group(order by Total_Orders) over() as prc_60_to,
percentile_disc(0.8) within group(order by Total_Orders) over() as prc_80_to,

percentile_disc(0.2) within group(order by Total_Spend) over() as prc_20_ts,
percentile_disc(0.4) within group(order by Total_Spend) over() as prc_40_ts,
percentile_disc(0.6) within group(order by Total_Spend) over() as prc_60_ts,
percentile_disc(0.8) within group(order by Total_Spend) over() as prc_80_ts
from prc_columns


-- Отримання дати від якої буде йти відлік для обрахування кількості днів


select max(InvoiceDate)
from dbo.online_retail_SQL


-- Створення view який обчислює 3 значення (кількість днів від останньої покупки, кількість замовлень, сума грошей)
-- Встановлення балів в залежності від розкиду даних
-- Присвоєння сегменту в залежності від балів кожному клієнту


create view segmentation_analysis as
with segmentation as (
	select
		Customer_ID,
		datediff(day, max(InvoiceDate), '2011-12-10') as recent_days_count,
		count(distinct Invoice) as total_orders,
		sum(Quantity * Price) as total_spend
	from dbo.online_retail_SQL
	where Customer_ID is not null
	group by Customer_ID
), 
	scores as (
	select *,
		case
			when recent_days_count <= 30 then 5
			when recent_days_count <= 90 then 4
			when recent_days_count <= 179 then 3
			when recent_days_count <= 270 then 2
			else 1
		end as r_score,

		case
			when total_orders <= 1 then 1
			when total_orders <= 2 then 2
			when total_orders <= 3 then 3
			when total_orders <= 6 then 4
			else 5
		end as o_score,

		case 
			when total_spend <= 250 then 1
			when total_spend <= 490 then 2
			when total_spend <= 942 then 3
			when total_spend <= 2059 then 4
			else 5
		end as s_score
	from segmentation
)
select *,
	case
		when r_score >= 4 and o_score >= 4 and s_score >= 4 then 'Best Customer'
		when r_score <= 1 then 'Lost Customer'
		when r_score >= 4 and o_score = 1 then 'New Customer'
		when r_score <= 2 and o_score >= 4 then 'At Risk/Inactive/Many orders'
		when r_score <= 2 and o_score < 4 then 'At Risk/Inactive/Few orders'
		when r_score > 2 and o_score < 4 then 'Recent/Few orders'
		when r_score > 2 and o_score >= 4 then 'Recent/Many orders'
		else 'Other'
	end as customer_segment
from scores

select *
from segmentation_analysis
where customer_segment = 'Other'




