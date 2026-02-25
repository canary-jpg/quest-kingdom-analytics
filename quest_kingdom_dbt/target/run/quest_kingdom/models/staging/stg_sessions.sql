
  
  create view "quest_kingdom"."main"."stg_sessions__dbt_tmp" as (
    with source as (
    select * from "quest_kingdom"."main"."sessions"
),

renamed as (
    select 
        session_id,
        player_id,
        --timestamps
        session_start::timestamp as session_started_at,
        session_end::timestamp as session_ended_at,

        --metrics
        session_duration_minutes,
        starting_level,
        ending_level,
        levels_gained,

        --derived metrics
        extract(hour from session_start::timestamp) as session_hour,
        extract(dow from session_start::timestamp) as session_day_of_week,
        date_trunc('day', session_start::timestamp)::date as session_date 
    from source
)

select * from renamed
  );
