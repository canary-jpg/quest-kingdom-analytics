{{
    config(
        materialized='table'
    )
}}

with sessions as (

    select * from {{ ref('fct_sessions') }}

),

-- Calculate days between sessions first
session_spacing as (

    select
        player_id,
        session_started_at,
        datediff('day', 
            lag(session_started_at) over (partition by player_id order by session_started_at), 
            session_started_at
        ) as days_since_last_session

    from sessions

),

-- Aggregate session metrics
session_metrics as (

    select
        s.player_id,
        s.attribution_channel,
        s.player_segment,
        s.experiment_variant,
        
        -- Session counts
        count(*) as total_sessions,
        count(case when s.is_quality_session then 1 end) as quality_sessions,
        count(case when s.has_progression then 1 end) as sessions_with_progression,
        
        -- Duration metrics
        avg(s.session_duration_minutes) as avg_session_duration,
        sum(s.session_duration_minutes) as total_play_time,
        max(s.session_duration_minutes) as longest_session,
        
        -- Progression metrics
        sum(s.levels_gained) as total_levels_gained,
        avg(s.levels_gained) as avg_levels_per_session,
        
        -- Time of day patterns
        count(case when s.time_of_day = 'morning' then 1 end) as morning_sessions,
        count(case when s.time_of_day = 'afternoon' then 1 end) as afternoon_sessions,
        count(case when s.time_of_day = 'evening' then 1 end) as evening_sessions,
        count(case when s.time_of_day = 'night' then 1 end) as night_sessions,
        
        -- Weekend vs weekday
        count(case when s.is_weekend then 1 end) as weekend_sessions,
        count(case when not s.is_weekend then 1 end) as weekday_sessions

    from sessions s
    group by s.player_id, s.attribution_channel, s.player_segment, s.experiment_variant

),

-- Calculate average spacing separately
avg_spacing as (

    select
        player_id,
        avg(days_since_last_session) as avg_days_between_sessions

    from session_spacing
    where days_since_last_session is not null
    group by player_id

),

-- Add derived metrics
final as (

    select
        sm.*,
        sp.avg_days_between_sessions,
        
        -- Quality rates
        round(sm.quality_sessions::float / sm.total_sessions * 100, 1) as quality_session_pct,
        round(sm.sessions_with_progression::float / sm.total_sessions * 100, 1) as progression_session_pct,
        
        -- Engagement patterns
        round(sm.weekend_sessions::float / sm.total_sessions * 100, 1) as weekend_session_pct,
        
        -- Preferred time of day
        case
            when sm.evening_sessions > sm.morning_sessions 
                and sm.evening_sessions > sm.afternoon_sessions 
                and sm.evening_sessions > sm.night_sessions 
            then 'Evening'
            when sm.morning_sessions > sm.afternoon_sessions 
                and sm.morning_sessions > sm.night_sessions 
            then 'Morning'
            when sm.afternoon_sessions > sm.night_sessions then 'Afternoon'
            else 'Night'
        end as preferred_play_time,
        
        -- Engagement tier
        case
            when sm.total_sessions >= 20 then 'Power User (20+)'
            when sm.total_sessions >= 10 then 'Engaged (10-19)'
            when sm.total_sessions >= 5 then 'Regular (5-9)'
            else 'Casual (1-4)'
        end as engagement_tier

    from session_metrics sm
    left join avg_spacing sp on sm.player_id = sp.player_id

)

select * from final