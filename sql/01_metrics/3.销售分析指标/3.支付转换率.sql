-- 3.支付转换率
-- 指标说明：统计周期内，已支付订单数占总下单数的比例
-- 说明：保留原始查询口径与计算逻辑；各查询可按需单独执行。

use ecommerce_analysis;

select
    count(distinct case when payment_status = 'PAID' then order_id end) as paid_orders,
    count(distinct order_id) as total_orders,
    round(count(distinct case when payment_status = 'PAID' then order_id end)
        / count(distinct order_id) * 100, 2) as payment_conversion_rate
from order_master
where order_time between date_sub(curdate(), interval 30 day) and curdate();
