select
    -- ids
    event_id,
    player_id,
    session_id,
    
    -- timestamps
    event_timestamp::timestamp as event_at,
    
    -- dimensions
    lower(trim(event_name)) as event_name,
    
    -- json properties
    event_properties

from "quest_kingdom"."main"."events"