-- 5.订单量
-- 指标说明：统计周期内的总下单数（含未支付、已取消）
-- 说明：保留原始查询口径与计算逻辑；各查询可按需单独执行。

use ecommerce_analysis;

select
    date(order_time) as order_date,
    count(order_id) as daily_orders
from order_master
where order_time between date_sub(curdate(), interval 30 day) and curdate()
group by date(order_time)order by order_date;
