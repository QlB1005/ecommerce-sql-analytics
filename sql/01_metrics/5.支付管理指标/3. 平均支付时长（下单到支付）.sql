-- 3. 平均支付时长（下单到支付）
-- 指标说明：统计周期内，用户从 “下单” 到 “支付成功” 的平均时间
-- 说明：保留原始查询口径与计算逻辑；各查询可按需单独执行。

use ecommerce_analysis;

select
    avg(timestampdiff(minute, order_time, payment_time)) as avg_payment_minutes
from order_master
where
    order_time between date_sub(curdate(), interval 30 day) and curdate()
    and payment_status = 'PAID';
