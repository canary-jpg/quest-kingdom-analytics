

with progression as (
    select * from "quest_kingdom"."main"."rpt_level_progression"
),

--count players who reached each level threshold
level_funnel as (
    select 
        count(*) as total_players,

        --level milestones
        sum(case when max_level_reached >= 1 then 1 else 0 end) as reached_level_1,
        sum(case when max_level_reached >= 5 then 1 else 0 end) as reached_level_5,
        sum(case when max_level_reached >= 10 then 1 else 0 end) as reached_level_10,
        sum(case when max_level_reached >= 15 then 1 else 0 end) as reached_level_15,
        sum(case when max_level_reached >= 20 then 1 else 0 end) as reached_level_20,
        sum(case when max_level_reached >= 25 then 1 else 0 end) as reached_level_25,
        sum(case when max_level_reached >= 30 then 1 else 0 end) as reached_level_30,
        sum(case when max_level_reached >= 35 then 1 else 0 end) as reached_level_35,
        sum(case when max_level_reached >= 40 then 1 else 0 end) as reached_level_40,
        sum(case when max_level_reached >= 45 then 1 else 0 end) as reached_level_45,
        sum(case when max_level_reached >= 50 then 1 else 0 end) as reached_level_50,

        --average time to each level
        avg(hours_to_level_5) as avg_hours_to_level_5,
        avg(hours_to_level_10) as avg_hours_to_level_10,
        avg(hours_to_level_20) as avg_hours_to_level_20
    from progression 

),

--unpivot to long format for earier analysis
unpivoted as (
    select 1 as level_threshold, reached_level_1 as players, total_players, null as avg_hours from level_funnel
    union all 
    select 5, reached_level_5, total_players, avg_hours_to_level_5 from level_funnel
    union all 
    select 10, reached_level_10, total_players, avg_hours_to_level_10 from level_funnel,
    union all
    select 15, reached_level_15, total_players, null from level_funnel 
    union all 
    select 20, reached_level_20, total_players, avg_hours_to_level_20 from level_funnel
    union all 
    select 25, reached_level_25, total_players, null from level_funnel
    union all 
    select 30, reached_level_30, total_players, null from level_funnel
    union all 
    select 35, reached_level_35, total_players, null from level_funnel 
    union all 
    select 40, reached_level_40, total_players, null from level_funnel
    union all 
    select 45, reached_level_45, total_players, null from level_funnel 
    union all 
    select 50, reached_level_50, total_players, null from level_funnel
),

--calculate percentages and drop-off
final as (
    select 
        level_threshold,
        players,
        round(players::float / total_players * 100, 2) as completion_pct,

        --drop-off from previous level
        lag(players) over (order by level_threshold) as previous_level_players,

        round((lag(players) over(order by level_threshold) - players)::float / 
              lag(players) over (order by level_threshold) * 100, 2) as drop_off_pct,
        
        avg_hours,
    from unpivoted 
)

select * from final 
order by level_threshold