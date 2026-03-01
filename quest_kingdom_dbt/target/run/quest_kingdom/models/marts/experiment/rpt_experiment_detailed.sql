
  
    
    

    create  table
      "quest_kingdom"."main"."rpt_experiment_detailed__dbt_tmp"
  
    as (
      

with players as (
    select * from "quest_kingdom"."main"."dim_players"
),

retention as (
    select * from "quest_kingdom"."main"."rpt_d1_d7_d30_retention"
),

progression as (
    select * from "quest_kingdom"."main"."rpt_level_progression"
),

ltv as (
    select * from "quest_kingdom"."main"."rpt_player_ltv"
),

--aggregate all metrics by variant
variant_summary as (
    select 
        p.experiment_variant,

        --sample size
        count(*) as total_users,
        
        --conversion 
        sum(case when p.is_payer then 1 else 0 end) as paying_users,
        round(sum(case when p.is_payer then 1 else 0 end)::float / count(*) * 100, 2) as conversion_rate_pct,

        --revenue
        round(sum(p.total_revenue), 2) as total_revenue,
        round(avg(p.total_revenue), 2) as arpu,
        round(avg(case when p.is_payer then p.total_revenue end), 2) as arppu,

        --retention
        round(avg(r.retained_d1::int)  * 100, 2) as d1_retention_pct,
        round(avg(r.retained_d7::int) * 100, 2) as d7_retention_pct,
        round(avg(r.retained_d30::int) * 100, 2) as d30_retention_pct,

        --engagement
        round(avg(p.total_sessions), 1) as avg_sessions,
        round(avg(p.total_play_time_minutes), 1) as avg_play_time_mins,

        --progression
        round(avg(pr.max_level_reached), 1) as avg_max_level,
        sum(case when pr.max_level_reached >= 10 then 1 else 0 end) as reached_level_10,
        round(avg(pr.levels_per_hour), 2) as avg_levels_per_hour,

        --ltv segments
        round(avg(case when ltv.converter_type = 'Fast Converted' then ltv.total_revenue end), 2) as fast_converter_ltv,
        round(avg(case when ltv.converter_type = 'Week 1 Converted' then ltv.total_revenue end), 2) as week1_converter_ltv
    from players p 
    left join retention r on p.player_id = r.player_id 
    left join progression pr on p.player_id = pr.player_id 
    left join ltv on p.player_id = ltv.player_id 
    where p.experiment_variant is not null 
    group by p.experiment_variant 
)

select * from variant_summary
order by experiment_variant
    );
  
  