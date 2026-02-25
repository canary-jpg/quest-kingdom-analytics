
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select ad_id
from "quest_kingdom"."main"."stg_ad_impressions"
where ad_id is null



  
  
      
    ) dbt_internal_test