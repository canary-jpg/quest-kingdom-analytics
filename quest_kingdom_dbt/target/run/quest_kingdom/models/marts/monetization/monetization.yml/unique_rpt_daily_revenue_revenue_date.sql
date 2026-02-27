
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    revenue_date as unique_field,
    count(*) as n_records

from "quest_kingdom"."main"."rpt_daily_revenue"
where revenue_date is not null
group by revenue_date
having count(*) > 1



  
  
      
    ) dbt_internal_test