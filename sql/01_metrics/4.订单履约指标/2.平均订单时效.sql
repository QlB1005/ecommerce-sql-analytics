-- 2.平均订单时效
-- 指标说明：统计周期内，订单从 “支付成功” 到 “用户签收” 的平均时长
-- 说明：保留原始查询口径与计算逻辑；各查询可按需单独执行。

use ecommerce_analysis;

select
    avg(timestampdiff(hour, payment_time, receive_time)) as avg_delivery_hours
from order_master
where
    order_time between date_sub(curdate(), interval 30 day) and curdate()and payment_status = 'PAID' and receive_time is not null;
