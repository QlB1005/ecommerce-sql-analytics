-- 4.复购率
-- 指标说明：统计周期内，消费≥2 次的用户占总付费用户的比例
-- 说明：保留原始查询口径与计算逻辑；各查询可按需单独执行。

-- 近30天用户复购率（消费≥2次的用户占比）
use ecommerce_analysis;

with user_purchase_counts as (select
        user_id,count(distinct order_id) as order_count  -- 统计用户订单数（去重）
        from order_master
        where order_time between date_sub(curdate(), interval 30 day) and curdate()
        and payment_status = 'PAID'  -- 仅统计已支付订单
        group by user_id
)
select
    count(distinct user_id) as total_paid_users,  -- 总付费用户数
    count(distinct case when order_count >= 2 then user_id end) as repurchase_users,  -- 复购用户数
    round(count(distinct case when order_count >= 2 then user_id end)
        / count(distinct user_id) * 100, 2) as repurchase_rate  -- 复购率
        from user_purchase_counts;
