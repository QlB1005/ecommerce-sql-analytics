-- 5.客单价
-- 指标说明：统计周期内，平均每个付费用户的消费总金额
-- 说明：保留原始查询口径与计算逻辑；各查询可按需单独执行。

use ecommerce_analysis;

select sum(payment_amount)/count(distinct user_id)
from order_master
where
    payment_status = 'PAID' and
    order_time between date_sub(curdate(), interval 30 day) and curdate();
