

with players as (
    select * from "quest_kingdom"."main"."dim_players"
),

sessions as (
    select * from "quest_kingdom"."main"."fct_sessions"
),

--get all dates a player was active
player_activity as (
    select 
        player_id,
        session_date as activity_date,
        count(*) as sessions_that_day,
        sum(session_duration_minutes) as total_play_time_minutes,
        max(ending_level) as max_level_that_day
    from sessions 
    group by player_id, session_date 
),

--join to player attributes
final as (
    select 
        pa.player_id,
        pa.activity_date,
        pa.sessions_that_day,
        pa.total_play_time_minutes,
        pa.max_level_that_day,

        --player context
        p.installed_at,
        p.attribution_channel,
        p.country,
        p.device_type,
        p.player_segment,
        p.experiment_variant,
        p.tutorial_completed,

        --derived metrics
        datediff('day', p.installed_at, pa.activity_date) as days_since_install,

        --cohort
        date_trunc('week', p.installed_at)::date as cohort_week,
        date_trunc('month', p.installed_at)::date as cohort_month
    from player_activity pa 
    inner join players p on pa.player_id = p.player_id 
)

select * from final