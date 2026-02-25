select
    -- ids
    ad_id,
    player_id,
    session_id,
    
    -- timestamps
    ad_timestamp::timestamp as shown_at,
    
    -- dimensions
    lower(trim(ad_type)) as ad_type,
    lower(trim(ad_network)) as ad_network,
    
    -- booleans
    clicked,
    
    -- metrics
    revenue_usd,
    
    -- derived
    date_trunc('day', ad_timestamp::timestamp)::date as ad_date

from "quest_kingdom"."main"."ad_impressions"