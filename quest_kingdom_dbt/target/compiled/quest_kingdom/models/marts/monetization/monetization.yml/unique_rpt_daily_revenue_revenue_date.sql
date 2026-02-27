
    
    

select
    revenue_date as unique_field,
    count(*) as n_records

from "quest_kingdom"."main"."rpt_daily_revenue"
where revenue_date is not null
group by revenue_date
having count(*) > 1


