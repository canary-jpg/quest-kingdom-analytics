

with players as (

    select * from "quest_kingdom"."main"."stg_players"

),

sessions as (

    select * from "quest_kingdom"."main"."stg_sessions"

),

transactions as (

    select * from "quest_kingdom"."main"."stg_iap_transactions"

),

ads as (

    select * from "quest_kingdom"."main"."stg_ad_impressions"

),

-- Aggregate session metrics per player
player_sessions as (

    select
        player_id,
        count(*) as total_sessions,
        min(session_started_at) as first_session_at,
        max(session_started_at) as last_session_at,
        sum(session_duration_minutes) as total_play_time_minutes,
        avg(session_duration_minutes) as avg_session_duration_minutes,
        max(ending_level) as max_level_reached

    from sessions
    group by player_id

),

-- Aggregate IAP metrics per player
player_iap as (

    select
        player_id,
        count(*) as total_purchases,
        sum(price_usd) as total_iap_revenue,
        min(purchased_at) as first_purchase_at,
        avg(price_usd) as avg_purchase_value

    from transactions
    group by player_id

),

-- Aggregate ad metrics per player
player_ads as (

    select
        player_id,
        count(*) as total_ad_impressions,
        sum(revenue_usd) as total_ad_revenue,
        sum(case when clicked then 1 else 0 end) as total_ad_clicks

    from ads
    group by player_id

),

-- Combine everything
final as (

    select
        -- player attributes
        p.player_id,
        p.installed_at,
        p.attribution_channel,
        p.country,
        p.device_type,
        p.player_segment,
        p.experiment_variant,
        p.tutorial_completed,
        
        -- session metrics
        coalesce(ps.total_sessions, 0) as total_sessions,
        ps.first_session_at,
        ps.last_session_at,
        coalesce(ps.total_play_time_minutes, 0) as total_play_time_minutes,
        ps.avg_session_duration_minutes,
        coalesce(ps.max_level_reached, 0) as max_level_reached,
        
        -- monetization metrics
        coalesce(pi.total_purchases, 0) as total_purchases,
        coalesce(pi.total_iap_revenue, 0) as total_iap_revenue,
        pi.first_purchase_at,
        pi.avg_purchase_value,
        
        coalesce(pa.total_ad_impressions, 0) as total_ad_impressions,
        coalesce(pa.total_ad_revenue, 0) as total_ad_revenue,
        coalesce(pa.total_ad_clicks, 0) as total_ad_clicks,
        
        -- derived total revenue
        coalesce(pi.total_iap_revenue, 0) + coalesce(pa.total_ad_revenue, 0) as total_revenue,
        
        -- derived days metrics
        datediff('day', p.installed_at, current_date) as days_since_install,
        case 
            when ps.last_session_at is not null 
            then datediff('day', ps.last_session_at, current_date)
            else null
        end as days_since_last_session,
        case 
            when pi.first_purchase_at is not null 
            then datediff('day', p.installed_at, pi.first_purchase_at)
            else null
        end as days_to_first_purchase,
        
        -- derived flags
        coalesce(ps.total_sessions, 0) > 0 as is_activated,
        coalesce(pi.total_purchases, 0) > 0 as is_payer,
        coalesce(pa.total_ad_impressions, 0) > 0 as has_seen_ads,

        --cohort fields
        date_trunc('week', p.installed_at)::date as cohort_week,
        date_trunc('month', p.installed_at)::date as cohort_month

    from players p
    left join player_sessions ps on p.player_id = ps.player_id
    left join player_iap pi on p.player_id = pi.player_id
    left join player_ads pa on p.player_id = pa.player_id

)

select * from final