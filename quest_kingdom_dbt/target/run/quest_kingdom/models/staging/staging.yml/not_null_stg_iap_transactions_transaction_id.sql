
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select transaction_id
from "quest_kingdom"."main"."stg_iap_transactions"
where transaction_id is null



  
  
      
    ) dbt_internal_test