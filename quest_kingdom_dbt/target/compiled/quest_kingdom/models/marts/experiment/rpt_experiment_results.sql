

with players as (
    select * from "quest_kingdom"."main"."dim_players"
),

retention as (
    select * from "quest_kingdom"."main"."rpt_d1_d7_d30_retention"
),

progression as (
    select * from "quest_kingdom"."main"."rpt_level_progression"
),

--get metrics by variant
variant_metrics as (
    select 
        p.experiment_variant,

        --sample sizes
        count(*) as total_users,

        --conversion metrics
        sum(case when p.is_payer then 1 else 0 end) as converted_users,
        sum(case when p.is_payer then 1 else 0 end)::float / count(*) as conversion_rate,

        --revenue metrics
        sum(p.total_revenue) as total_revenue,
        avg(case when p.is_payer then p.total_revenue end) as avg_revenue_per_payer,
        avg(p.total_revenue) as arpu,

        --retention metrics
        avg(r.retained_d1::int) as d1_retention_rate,
        avg(r.retained_d7::int) as d7_retention_rate,
        avg(r.retained_d30::int) as d30_retention_rate,

        --engagement metrics
        avg(p.total_sessions) as avg_sessions,
        avg(p.total_play_time_minutes) as avg_play_time,

        --progression metrics
        avg(pr.max_level_reached) as avg_max_level,
        avg(pr.levels_per_hour) as avg_progression_velocity
    from players p 
    left join retention r on p.player_id = r.player_id 
    left join progression pr on p.player_id = pr.player_id 
    where p.experiment_variant is not null 
    group by p.experiment_variant
),

--calculate statistical significance for key metrics
stats as (
    select 
        'control' as variant_a,
        'variant_a' as variant_b,

        --control metrics
        (select conversion_rate from variant_metrics where experiment_variant = 'control') as control_conversion,
        (select total_users from variant_metrics where experiment_variant = 'control') as control_n,

        --variant A metrics
        (select conversion_rate from variant_metrics where experiment_variant = 'variant_a') as variant_a_conversion,
        (select total_users from variant_metrics where experiment_variant = 'variant_a') as variant_a_n 

    union all 

    select 
        'control' as variant_a,
        'variant_b' as variant_b,

        (select conversion_rate from variant_metrics where experiment_variant = 'control') as control_conversion,
        (select total_users from variant_metrics where experiment_variant = 'control') as control_n,

        (select conversion_rate from variant_metrics where experiment_variant = 'variant_b') as variant_b_conversion,
        (select total_users from variant_metrics where experiment_variant = 'variant_b') as variant_b_n
),

--two-proportion z-test
z_test as (
    select 
        *,

        --pooled proportion
        (control_n * control_conversion + variant_a_n * variant_a_conversion) /
        (control_n + variant_a_n) as pooled_b,

        --standard error
        sqrt(
            ((control_n * control_conversion + variant_a_n * variant_a_conversion) /
            (control_n + variant_a_n)) * 
            (1 - (control_n * control_conversion + variant_a_n * variant_a_conversion) /
            (control_n + variant_a_n)) *
            (1.0/control_n * 1.0/variant_a_n)
        ) as se,

        --absolute and relative lift
        variant_a_conversion - control_conversion as absolute_lift,
        (variant_a_conversion - control_conversion) / nullif(control_conversion, 0) * 100 as relative_lift_pct
    from stats 
),

--calculate z-score and significance
final as (
    select 
        variant_a,
        variant_b,
        control_n as variant_a_users,
        variant_a_n as variant_b_users,
        round(control_conversion * 100, 2) as variant_a_conversion_rate,
        round(variant_a_conversion * 100, 2) as variant_b_conversion_pct,
        round(absolute_lift * 100, 2) as absolute_lift_pct,
        round(relative_lift_pct, 2) as relative_lift_pct,

        --z-score
        round((variant_a_conversion - control_conversion) / nullif(se, 0), 2) as z_score,

        --95% confidence interval
        round((absolute_lift - 1.96 * se) * 100, 2) as ci_lower_pct,
        round((absolute_lift + 1.96 * se) * 100, 2) as ci_upper_pct,

        --statistical signifiance (z > 1.96 or z < -1.96)
        abs((variant_a_conversion - control_conversion) / nullif(se, 0)) > 1.96 as is_significant,

        --winner
        case 
            when abs((variant_a_conversion - control_conversion) / nullif(se, 0)) <= 1.95 then 'No Clear Winner'
            when variant_a_conversion > control_conversion then variant_b
            else variant_b 
        end as winner 
    from z_test
)

select * from final