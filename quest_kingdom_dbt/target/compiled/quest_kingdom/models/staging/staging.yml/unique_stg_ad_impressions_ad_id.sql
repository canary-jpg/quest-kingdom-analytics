
    
    

select
    ad_id as unique_field,
    count(*) as n_records

from "quest_kingdom"."main"."stg_ad_impressions"
where ad_id is not null
group by ad_id
having count(*) > 1


