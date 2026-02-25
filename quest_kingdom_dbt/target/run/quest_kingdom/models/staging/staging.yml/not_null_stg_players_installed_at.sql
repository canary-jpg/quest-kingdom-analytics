
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select installed_at
from "quest_kingdom"."main"."stg_players"
where installed_at is null



  
  
      
    ) dbt_internal_test