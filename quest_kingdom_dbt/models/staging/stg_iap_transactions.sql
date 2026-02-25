select
    -- ids
    transaction_id,
    player_id,
    session_id,
    
    -- timestamps
    transaction_timestamp::timestamp as purchased_at,
    
    -- dimensions
    lower(trim(sku)) as sku,
    lower(trim(platform)) as platform,
    
    -- metrics
    price_usd,
    gems_purchased,
    
    -- derived
    date_trunc('day', transaction_timestamp::timestamp)::date as purchase_date

from {{ source('raw', 'iap_transactions') }}