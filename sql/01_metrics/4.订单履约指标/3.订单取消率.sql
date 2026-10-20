-- 3.订单取消率
-- 指标说明：统计周期内，用户取消的未支付订单数占总下单数的比例
-- 说明：保留原始查询口径与计算逻辑；各查询可按需单独执行。

use ecommerce_analysis;

-- 近30天订单取消率（未支付且超时未支付的订单占比）
select
    count(distinct o.order_id) as total_orders,  -- 总订单数
    count(distinct case
        when o.payment_status = 'UNPAID'
        and timestampdiff(hour, o.order_time, now()) > 24  -- 超过24小时未支付视为取消
        then o.order_id
    end) as cancel_orders,  -- 取消订单数
    round(count(distinct case
            when o.payment_status = 'UNPAID'
            and timestampdiff(hour, o.order_time, now()) > 24
            then o.order_id
        end) / count(distinct o.order_id) * 100, 2) as cancel_rate  -- 取消率
from order_master o
where o.order_time between date_sub(curdate(), interval 30 day) and curdate();
