
  
    
    

    create  table
      "quest_kingdom"."main"."rpt_daily_revenue__dbt_tmp"
  
    as (
      

with daily_active_users as (
    select * from "quest_kingdom"."main"."fct_daily_active_users"
),

iap_transactions as (
    select * from "quest_kingdom"."main"."stg_iap_transactions"
),

ad_impressions as (
    select * from "quest_kingdom"."main"."stg_ad_impressions"
),

--daily IAP revenue
daily_iap as (
    select
        purchase_date as revenue_date,
        count(distinct player_id) as paying_users,
        count(*) as transactions,
        sum(price_usd) as iap_revenue,
        avg(price_usd) as avg_transaction_value
    from iap_transactions
    group by purchase_date
),

--daily ad revenue
daily_ads as (
    select 
        ad_date as revenue_date,
        count(distinct player_id) as users_with_ads,
        count(*) as impressions,
        sum(revenue_usd) as ad_revenue,
        sum(case when clicked then 1 else 0 end) as clicks
    from ad_impressions
    group by ad_date 
),

--daily active users
daily_dau as (
    select 
        activity_date as revenue_date,
        count(distinct player_id) as dau 
    from daily_active_users
    group by activity_date
),

--combine all metrics
final as (
    select
        coalesce(d.revenue_date, i.revenue_date, a.revenue_date) as revenue_date,
        --user counts
        coalesce(d.dau, 0) as dau,
        coalesce(i.paying_users, 0) as paying_users,
        coalesce(a.users_with_ads, 0) as users_with_ads,
        --revenue
        coalesce(i.iap_revenue, 0) as iap_revenue,
        coalesce(a.ad_revenue, 0) as ad_revenue,
        coalesce(i.iap_revenue, 0) + coalesce(a.ad_revenue, 0) as total_revenue,
        --transactions and impressions
        coalesce(i.transactions, 0) as iap_transactions,
        coalesce(a.impressions, 0) as ad_impressions,
        coalesce(a.clicks, 0) as ad_clicks,
        --per-transaction metrics
        i.avg_transaction_value,
        --ARPDAU (average revenue per daily active user)
        case
            when coalesce(d.dau, 0) > 0
            then (coalesce(i.iap_revenue, 0) + coalesce(a.ad_revenue, 0)) / d.dau
            else 0
        end as arpdau,
        --ARPPU (average revenue per paying user)
        case
            when coalesce(i.paying_users, 0) > 0
            then coalesce(i.iap_revenue, 0) / i.paying_users
            else 0
        end as arppu,
        --conversion rate (paying users /DAU)
        case
            when coalesce(d.dau, 0) > 0
            then coalesce(i.paying_users, 0)::float / d.dau * 100
            else 0
        end as daily_conversion_rate,
        --ad metrics
        case 
            when coalesce(a.impressions, 0) > 0
            then coalesce(a.clicks, 0)::float / a.impressions * 100
            else 0
        end as ad_ctr
    from daily_dau d 
    full outer join daily_iap i on d.revenue_date = i.revenue_date
    full outer join daily_ads a on d.revenue_date = a.revenue_date
)

select * from final
order by revenue_date
    );
  
  