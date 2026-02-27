
    
    

select
    player_id as unique_field,
    count(*) as n_records

from "quest_kingdom"."main"."rpt_feature_engagement"
where player_id is not null
group by player_id
having count(*) > 1


