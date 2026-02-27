
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select level_threshold
from "quest_kingdom"."main"."rpt_level_funnel"
where level_threshold is null



  
  
      
    ) dbt_internal_test