

with daily_activity as (
    select * from "quest_kingdom"."main"."fct_daily_active_users"
),

--calculate weeks since install for each activity
activity_by_week as (
    select 
        player_id,
        cohort_week,
        activity_date,
        days_since_install,
        floor(days_since_install / 7) as weeks_since_install
    from daily_activity
),

--get cohort sizes
cohort_sizes as (
    select 
        cohort_week,
        count(distinct player_id) as cohort_size 
    from activity_by_week
    group by cohort_week 
),

--count active users by cohort and week
cohort_activity as (
    select 
        cohort_week,
        weeks_since_install,
        count(distinct player_id) as active_users 
    from activity_by_week
    group by cohort_week, weeks_since_install
),

--calculate retention percentages
cohort_retention as (
    select 
        ca.cohort_week,
        cs.cohort_size,
        ca.weeks_since_install,
        ca.active_users,
        round(ca.active_users::float / cs.cohort_size * 100, 2) as retention_pct
    from cohort_activity ca 
    inner join cohort_sizes cs on ca.cohort_week = cs.cohort_week
),

--pivot to wide format for easier analysis
pivoted as (
    select 
        cohort_week,
        cohort_size,

        max(case when weeks_since_install = 0 then retention_pct end) as week_0,
        max(case when weeks_since_install = 1 then retention_pct end) as week_1,
        max(case when weeks_since_install = 2 then retention_pct end) as week_2,
        max(case when weeks_since_install = 3 then retention_pct end) as week_3,
        max(case when weeks_since_install = 4 then retention_pct end) as week_4,
        max(case when weeks_since_install = 5 then retention_pct end) as week_5,
        max(case when weeks_since_install = 6 then retention_pct end) as week_6,
        max(case when weeks_since_install = 7 then retention_pct end) as week_7,
        max(case when weeks_since_install = 8 then retention_pct end) as week_8,
        max(case when weeks_since_install = 9 then retention_pct end) as week_9,
        max(case when weeks_since_install = 10 then retention_pct end) as week_10,
        max(case when weeks_since_install = 11 then retention_pct end) as week_11,
        max(case when weeks_since_install = 12 then retention_pct end) as week_12,
    from cohort_retention
    group by cohort_week, cohort_size
)

select * from pivoted 
order by cohort_week desc