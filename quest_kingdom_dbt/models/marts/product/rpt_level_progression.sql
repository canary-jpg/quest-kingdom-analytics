{{
    config(
        materialized='table'
    )
}}

with sessions as (
    select * from {{ ref('fct_sessions') }}
),

players as (
    select * from {{ ref('dim_players') }}
),

--track level progression per player
player_levels as (
    select 
        player_id,
        min(session_started_at) as first_session_at,
        max(ending_level) as max_level_reached,
        sum(levels_gained) as total_levels_gained,

        --time to reach certain milestones
        min(case when ending_level >= 5 then session_started_at end) as reached_level_5_at,
        min(case when ending_level >= 10 then session_started_at end) as reached_level_10_at,
        min(case when ending_level >= 20 then session_started_at end) as reached_level_20_at,
        min(case when ending_level >= 30 then session_started_at end) as reached_level_30_at,
        min(case when ending_level >= 40 then session_started_at end) as reached_level_40_at,
        min(case when ending_level >= 50 then session_started_at end) as reached_level_50_at,

        --progression metrics
        count(*) as total_sessions,
        sum(session_duration_minutes) as total_play_time,
        avg(session_duration_minutes) as avg_session_duration
    from sessions 
    group by player_id 
),

--combine with player attributes
final as (
    select 
        pl.player_id,
        p.installed_at,
        p.cohort_week,
        p.attribution_channel,
        p.player_segment,
        p.experiment_variant,
        p.is_payer,

        --progression
        pl.max_level_reached,
        pl.total_levels_gained,

        --milestones
        pl.reached_level_5_at,
        pl.reached_level_10_at,
        pl.reached_level_20_at,
        pl.reached_level_30_at,
        pl.reached_level_40_at,
        pl.reached_level_50_at,

        --time to milestones (in hours)
        case 
            when pl.reached_level_5_at is not null 
            then datediff('hour', pl.first_session_at, pl.reached_level_5_at)
        end as hours_to_level_5,
        case 
            when pl.reached_level_10_at is not null 
            then datediff('hour', pl.first_session_at, pl.reached_level_10_at)
        end as hours_to_level_10,
        case 
            when pl.reached_level_20_at is not null 
            then datediff('hour', pl.first_session_at, pl.reached_level_20_at)
        end as hours_to_level_20,
       
       --engagement
       pl.total_sessions,
       pl.total_play_time,
       pl.avg_session_duration,

       --progression velocity (levels per hour player)
       case 
            when pl.total_play_time > 0 
            then pl.total_levels_gained::float / (pl.total_play_time / 60)
            else 0
        end as levels_per_hour,

        --progression tiers
        case 
            when pl.max_level_reached >= 40 then 'End Game (40+)'
            when pl.max_level_reached >= 30 then 'Late Game (30-39)'
            when pl.max_level_reached >= 20 then 'Mid Game (20-29)'
            when pl.max_level_reached >= 10 then 'Early Game (10-19)'
            when pl.max_level_reached >= 5 then 'Tutorial+ (5-9)'
            else 'Tutorial (1-4)'
        end as progression_tier 
    from player_levels pl 
    inner join players p on pl.player_id = p.player_id
)

select * from final 