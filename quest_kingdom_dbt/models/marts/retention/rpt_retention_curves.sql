{{
    config(
        materialized='table'
    )
}}

with daily_activity as (
    select * from {{ ref('fct_daily_active_users') }}
),

--calculate weeks since install
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

--countr active users by cohort and week
cohort_activity as (
    select 
        cohort_week,
        weeks_since_install,
        count(distinct player_id) as active_users 
    from activity_by_week
    where weeks_since_install <= 12 --only tracking the first 12 weeks
    group by cohort_week, weeks_since_install
),

--calculate retention
final as (
    select
        ca.cohort_week,
        cs.cohort_size,
        ca.weeks_since_install,
        ca.active_users,
        ca.active_users::float / cs.cohort_size as retention_rate,
        round(ca.active_users::float / cs.cohort_size * 100, 1) as retention_pct,
        --cohort label for charts
        cs.cohort_week::varchar || ' Cohort' as cohort_label
    from cohort_activity ca 
    inner join cohort_sizes cs on ca.cohort_week = cs.cohort_week
)

select * from final
order by cohort_week, weeks_since_install