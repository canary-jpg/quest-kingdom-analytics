
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select revenue_date
from "quest_kingdom"."main"."rpt_daily_revenue"
where revenue_date is null



  
  
      
    ) dbt_internal_test