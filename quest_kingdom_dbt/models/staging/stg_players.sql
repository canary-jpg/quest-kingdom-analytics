with source as (
    select * from {{ source('raw', 'players') }}
),

renamed as (
    select
        player_id,
        install_date::date as installed_at,
        --dimensions
        lower(trim(attribution_channel)) as attribution_channel,
        lower(trim(country)) as country,
        lower(trim(device_type)) as device_type,
        lower(trim(player_segment)) as player_segment,
        lower(trim(experiment_variant)) as experiment_variant,
        --booleans
        tutorial_completed,
        --metrics
        lifetime_value as lifetime_value_usd
    from source 
)

select * from renamed