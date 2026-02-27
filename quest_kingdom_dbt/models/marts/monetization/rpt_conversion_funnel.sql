{{
    config(
        materialized='table'
    )
}}

with players as (
    select * from {{ ref('dim_players') }}
),

--define funnel stages
player_funnel as (
    select 
        player_id,
        installed_at,
        cohort_week,
        attribution_channel,
        player_segment,
        experiment_variant,

        --funnel stages (boolean)
        true as stage_1_installed,
        tutorial_completed as stage_2_tutorial_completed,
        is_activated as stage_3_had_session,
        max_level_reached >= 5 as stage_4_reached_level_5,
        is_payer as stage_5_first_purchase,

        --time to each stage
        0 as days_to_install,
        case when tutorial_completed then 0 else null end as days_to_tutorial,
        case when is_activated then 0 else null end as days_to_first_session,
        case when max_level_reached >= 5 then days_to_first_purchase else null end as days_to_level_5,
        days_to_first_purchase
    from players 
)

select * from player_funnel