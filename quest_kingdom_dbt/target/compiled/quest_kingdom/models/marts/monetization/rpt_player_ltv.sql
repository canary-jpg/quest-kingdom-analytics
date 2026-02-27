

with players as (

    select * from "quest_kingdom"."main"."dim_players"

),

daily_activity as (

    select * from "quest_kingdom"."main"."fct_daily_active_users"

),

-- Count active days per player
player_active_days as (

    select
        player_id,
        count(distinct activity_date) as total_active_days

    from daily_activity
    group by player_id

),

-- Calculate LTV for each player
player_ltv as (

    select
        p.player_id,
        p.installed_at,
        p.cohort_week,
        p.cohort_month,
        p.attribution_channel,
        p.country,
        p.device_type,
        p.player_segment,
        p.experiment_variant,
        p.tutorial_completed,
        
        -- Revenue
        p.total_iap_revenue,
        p.total_ad_revenue,
        p.total_revenue,
        
        -- Purchase behavior
        p.total_purchases,
        p.first_purchase_at,
        p.days_to_first_purchase,
        p.avg_purchase_value,
        
        -- Engagement
        p.total_sessions,
        coalesce(pad.total_active_days, 0) as total_active_days,
        p.total_play_time_minutes,
        p.max_level_reached,
        
        -- Derived metrics
        case 
            when coalesce(pad.total_active_days, 0) > 0 
            then p.total_revenue / pad.total_active_days
            else 0
        end as revenue_per_active_day,
        
        case 
            when p.total_sessions > 0 
            then p.total_revenue / p.total_sessions
            else 0
        end as revenue_per_session,
        
        case 
            when p.total_purchases > 0 
            then p.total_iap_revenue / p.total_purchases
            else 0
        end as avg_iap_value,
        
        -- Days since install
        p.days_since_install,
        
        -- Flags
        p.is_payer,
        case 
            when p.total_revenue > 0 and p.days_to_first_purchase <= 1 then 'Fast Converter'
            when p.total_revenue > 0 and p.days_to_first_purchase <= 7 then 'Week 1 Converter'
            when p.total_revenue > 0 and p.days_to_first_purchase <= 30 then 'Month 1 Converter'
            when p.total_revenue > 0 then 'Late Converter'
            else 'Non-Payer'
        end as converter_type

    from players p
    left join player_active_days pad on p.player_id = pad.player_id

)

select * from player_ltv