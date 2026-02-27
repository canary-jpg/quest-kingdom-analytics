

with events as (
    select * from "quest_kingdom"."main"."stg_events"
),

players as (
    select * from "quest_kingdom"."main"."dim_players"
),

--aggregate events per player
player_events as (
    select 
        player_id,

        --event counts
        count(*) as total_events,
        count(distinct event_name) as unique_event_types,

        --specific events
        sum(case when event_name = 'tutorial_completed' then 1 else 0 end) as tutorial_completions,
        sum(case when event_name = 'level_completed' then 1 else 0 end) as level_completions,
        sum(case when event_name = 'boss_defeated' then 1 else 0 end) as boss_defeats,

        --timing
        min(event_at) as first_event_at,
        max(event_at) as last_event_at
    from events 
    group by player_id 

),

--combine with player data
final as (
    select 
        p.player_id,
        p.installed_at,
        p.cohort_week,
        p.attribution_channel,
        p.player_segment,
        p.experiment_variant,
        p.is_payer,

        --events
        coalesce(pe.total_events, 0) as total_events,
        coalesce(pe.unique_event_types, 0) as unique_event_types,
        coalesce(pe.tutorial_completions, 0) as tutorial_completions,
        coalesce(pe.boss_defeats, 0) as boss_defeats,

        --derived
        case 
            when pe.tutorial_completions > 0 then true 
            else false 
        end as completed_tutorial,

        case
            when pe.boss_defeats > 0 then true
            else false 
        end defeated_boss,

        --events per session (if they have sessions)
        case
            when p.total_sessions > 0 
            then coalesce(pe.total_events, 0)::float / p.total_sessions
            else 0
        end events_per_session,

        --engagement level based on events
        case 
            when coalesce(pe.total_events, 0) >= 50 then 'Power User (50+)'
            when coalesce(pe.total_events, 0) >= 20 then 'Engaged (20-49)'
            when coalesce(pe.total_events, 0) >= 5 then 'Active (5-19)'
            when coalesce(pe.total_events, 0) >= 1 then 'Casual (1-4)'
            else 'No Events'
        end as event_engagement_tier
    from players p 
    left join player_events pe on p.player_id = pe.player_id 
 )

 
 select * from final