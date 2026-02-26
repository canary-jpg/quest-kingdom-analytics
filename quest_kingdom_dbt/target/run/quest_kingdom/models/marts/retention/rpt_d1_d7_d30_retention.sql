
  
    
    

    create  table
      "quest_kingdom"."main"."rpt_d1_d7_d30_retention__dbt_tmp"
  
    as (
      

with players as (
    select * from "quest_kingdom"."main"."dim_players"
),

daily_activity as (
    select * from "quest_kingdom"."main"."fct_daily_active_users"
),

--for each player, chekc if they were active on D1, D7, D30
player_retention as (
    select 
        p.player_id,
        p.installed_at,
        p.attribution_channel,
        p.country,
        p.device_type,
        p.player_segment,
        p.experiment_variant,
        p.tutorial_completed,
        p.cohort_week,
        p.cohort_month,

        --D1: active on day after install
        max(case when da.days_since_install = 1 then 1 else 0 end) as retained_d1,
        -- D7: active 7 days after install
        max(case when da.days_since_install = 7 then 1 else 0 end) as retained_d7,
        -- D30: active 30 days after install
        max(case when da.days_since_install = 30 then 1 else 0 end) as retained_d30,

        --also need to track if active in ranges (should be more forgiving)
        max(case when da.days_since_install between 1 and 1 then 1 else 0 end) as active_d1_window,
        max(case when da.days_since_install between 6 and 8 then 1 else 0 end) as active_d7_window,
        max(case when da.days_since_install between 28 and 32 then 1 else 0 end) as active_d30_window,

        --total days active
        count(distinct da.activity_date) as total_active_days
    from players p 
    left join daily_activity da on p.player_id = da.player_id 
    group by 
        p.player_id, p.installed_at, p.attribution_channel, p.country,
        p.device_type, p.player_segment, p.experiment_variant,
        p.tutorial_completed, p.cohort_week, p.cohort_month 
)

select * from player_retention
    );
  
  