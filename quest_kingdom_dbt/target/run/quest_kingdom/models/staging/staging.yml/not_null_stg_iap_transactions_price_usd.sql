
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select price_usd
from "quest_kingdom"."main"."stg_iap_transactions"
where price_usd is null



  
  
      
    ) dbt_internal_test