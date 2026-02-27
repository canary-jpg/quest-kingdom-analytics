

with transactions as (
    select * from "quest_kingdom"."main"."stg_iap_transactions"
),

players as (
    select * from "quest_kingdom"."main"."dim_players"
),

--aggregate by SKU
sku_metrics as (
    select 
        t.sku,
        --purchase counts
        count(*) as total_purchases,
        count(distinct t.player_id) as unique_buyers,

        --revenue
        sum(t.price_usd) as total_revenue,
        avg(t.price_usd) as avg_price,

        --virtual currency
        sum(t.gems_purchased) as total_gems_sold,
        avg(t.gems_purchased) as avg_gems_per_purchase,

        --platform split
        sum(case when t.platform = 'ios' then t.price_usd else 0 end) as ios_revenue,
        sum(case when t.platform = 'android' then t.price_usd else 0 end) as android_revenue,

        --timing
        min(t.purchased_at) as first_purchase_date,
        max(t.purchased_at) as last_purchase_date
    from transactions t 
    group by t.sku
),

--get buyer segments for each SKU
sku_by_segment as (
    select 
        t.sku,
        p.player_segment,
        count(*) as purchases,
        sum(t.price_usd) as revenue
    from transactions t 
    inner join players p on t.player_id = p.player_id 
    group by t.sku, p.player_segment 
),

--pivot segments
sku_segment_pivot as (
    select 
        sku,
        sum(case when player_segment = 'whale' then purchases else 0 end) as whale_purchases,
        sum(case when player_segment = 'dolphin' then purchases else 0 end) as dolphin_purchases,
        sum(case when player_segment = 'minnow' then purchases else 0 end) as minnow_purchases,
        sum(case when player_segment = 'whale' then revenue else 0 end) as whale_revenue,
        sum(case when player_segment = 'dolphin' then revenue else 0 end) as dolphin_revenue,
        sum(case when player_segment = 'minnow' then revenue else 0 end) as minnow_revenue
    from sku_by_segment
    group by sku

),

--combine
final as (
    select 
        sm.*,
        sp.whale_purchases,
        sp.dolphin_purchases,
        sp.minnow_purchases,
        sp.whale_revenue,
        sp.dolphin_revenue,
        sp.minnow_revenue,

        --derived metrics
        sm.total_revenue / sm.total_purchases as revenue_per_purchase,
        sm.total_purchases::float / sm.unique_buyers as purchases_per_buyer,

        --revenue share
        round(sm.total_revenue / sum(sm.total_revenue) over() * 100, 2) as revenue_share_pct
    from sku_metrics sm 
    left join sku_segment_pivot sp on sm.sku = sp.sku 
)

select * from final 
order by total_revenue desc