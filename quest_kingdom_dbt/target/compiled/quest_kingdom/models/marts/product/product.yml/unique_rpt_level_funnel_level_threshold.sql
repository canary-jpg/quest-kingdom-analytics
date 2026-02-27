
    
    

select
    level_threshold as unique_field,
    count(*) as n_records

from "quest_kingdom"."main"."rpt_level_funnel"
where level_threshold is not null
group by level_threshold
having count(*) > 1


