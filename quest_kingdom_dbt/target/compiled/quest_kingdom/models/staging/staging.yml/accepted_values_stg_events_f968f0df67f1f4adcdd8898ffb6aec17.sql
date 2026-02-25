
    
    

with all_values as (

    select
        event_name as value_field,
        count(*) as n_records

    from "quest_kingdom"."main"."stg_events"
    group by event_name

)

select *
from all_values
where value_field not in (
    'tutorial_completed','level_completed','boss_defeated'
)


