-- rfm_90.sql
-- 窗口与渠道 roi 对齐：2025-12-17 ~ 2026-03-17，只算 paid
-- r：距 2026-03-17 最近一次购买天数，<=45 高、<=75 中、否则低
-- f：窗内订单次数，>=3 高、=2 中、=1 低
-- m：用户 gmv 从高到低累计，至 80% 金额为高、至 95% 为中、其余为低（不是前 20% 的人）

drop table if exists rfm_90;

create table rfm_90 as
with r_data as (
    select user_id,
           datediff('2026-03-17', max(order_time)) as r_value,
           case
               when datediff('2026-03-17', max(order_time)) <= 45 then '高'
               when datediff('2026-03-17', max(order_time)) <= 75 then '中'
               else '低'
           end as r
    from order_master
    where order_time >= '2025-12-17'
      and order_time <= '2026-03-17 23:59:59'
      and payment_status = 'paid'
    group by user_id
),
f_data as (
    select user_id,
           count(order_id) as f_value,
           case
               when count(order_id) >= 3 then '高'
               when count(order_id) = 2 then '中'
               else '低'
           end as f
    from order_master
    where order_time >= '2025-12-17'
      and order_time <= '2026-03-17 23:59:59'
      and payment_status = 'paid'
    group by user_id
),
m_data as (
    with sum_temp as (
        select user_id,
               sum(payment_amount) as total_amount
        from order_master
        where order_time >= '2025-12-17'
          and order_time <= '2026-03-17 23:59:59'
          and payment_status = 'paid'
        group by user_id
    ),
    ranked_temp as (
        select user_id,
               total_amount,
               sum(total_amount) over (order by total_amount desc)
                   / (select sum(total_amount) from sum_temp) as cum_percent
        from sum_temp
    )
    select user_id,
           total_amount,
           case
               when cum_percent <= 0.80 then '高'
               when cum_percent <= 0.95 then '中'
               else '低'
           end as m
    from ranked_temp
)
select r.user_id,
       r.r,
       r.r_value,
       f.f,
       f.f_value,
       m.m,
       m.total_amount,
       concat(r.r, f.f, m.m) as rfm_code,
       case
           when r.r = '高' and f.f = '高' and m.m = '高' then '重要价值客户 (VIP)'
           when r.r = '高' and f.f = '高' and m.m = '低' then '重要发展客户 (需提客单)'
           when r.r = '高' and f.f = '低' and m.m = '高' then '重要保持客户 (需维持)'
           when r.r = '低' and f.f = '高' and m.m = '高' then '重要挽留客户 (需召回!)'
           when r.r = '低' and f.f = '低' and m.m = '低' then '低价值客户 (路人)'
           else '普通客户'
       end as customer_tag
from r_data r
join f_data f on r.user_id = f.user_id
join m_data m on r.user_id = m.user_id;


-- 分层结果：同时看人数占比和金额占比
select customer_tag,
       count(distinct user_id) as 用户数,
       round(count(distinct user_id) / (select count(distinct user_id) from rfm_90), 4) as 人数占比,
       round(sum(total_amount), 2) as 总金额,
       round(sum(total_amount) / (select sum(total_amount) from rfm_90), 4) as 金额占比
from rfm_90
group by customer_tag
order by 金额占比 desc;