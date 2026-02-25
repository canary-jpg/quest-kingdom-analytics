
    
    

with all_values as (

    select
        player_segment as value_field,
        count(*) as n_records

    from "quest_kingdom"."main"."stg_players"
    group by player_segment

)

select *
from all_values
where value_field not in (
    'whale','dolphin','minnow','non_payer'
)


