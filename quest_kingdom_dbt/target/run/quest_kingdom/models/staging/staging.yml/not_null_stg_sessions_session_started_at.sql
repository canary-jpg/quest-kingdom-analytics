
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select session_started_at
from "quest_kingdom"."main"."stg_sessions"
where session_started_at is null



  
  
      
    ) dbt_internal_test