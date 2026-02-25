

with sessions as (
    select * from "quest_kingdom"."main"."stg_sessions"
),

players as (
    select * from "quest_kingdom"."main"."stg_players"
),

final as (
    select 
        s.session_id,
        s.player_id,
        s.session_started_at,
        s.session_ended_at,
        s.session_duration_minutes,
        s.starting_level,
        s.ending_level,
        s.levels_gained,
        s.session_hour,
        s.session_day_of_week,
        s.session_date,

        --player context
        p.installed_at,
        p.attribution_channel,
        p.country,
        p.device_type,
        p.player_segment,
        p.experiment_variant,
        p.tutorial_completed,

        --derived metrics
        datediff('day', p.installed_at, s.session_started_at) as days_since_install,
        --session quality flags
        s.session_duration_minutes >= 5 as is_quality_session,
        s.levels_gained > 0 as has_progression,

        --time of day flags
        case 
            when s.session_hour between 0 and 5 then 'night'
            when s.session_hour between 6 and 11 then 'morning'
            when s.session_hour between 12 and 17 then 'afternoon'
            when s.session_hour between 18 and 23 then 'evening'
        end as time_of_day,

        --weekend flag
        s.session_day_of_week in (0, 6) as is_weekend
    from sessions s 
    left join players p on s.player_id = p.player_id 
)

select * from final