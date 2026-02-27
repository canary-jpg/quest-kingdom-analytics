
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select sku
from "quest_kingdom"."main"."rpt_sku_performance"
where sku is null



  
  
      
    ) dbt_internal_test