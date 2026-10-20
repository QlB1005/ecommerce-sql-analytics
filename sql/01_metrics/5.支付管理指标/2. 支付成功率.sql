-- 2. 支付成功率
-- 指标说明：统计周期内，支付成功的订单数占支付尝试次数的比例
-- 说明：保留原始查询口径与计算逻辑；各查询可按需单独执行。

use ecommerce_analysis;
select
    count(distinct case when payment_status = 'SUCCESS' then payment_id end) as success_payments,
    count(distinct payment_id) as total_payments,
    round(count(distinct case when payment_status = 'SUCCESS' then payment_id end)
        / count(distinct payment_id) * 100, 2) as payment_success_rate
from payment_record
where payment_time between date_sub(curdate(), interval 30 day) and curdate();
