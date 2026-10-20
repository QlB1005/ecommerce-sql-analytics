-- 2. 实际销售额（有效 GMV）
-- 指标说明：统计周期内已支付订单的总金额（剔除未支付、已取消、已退款订单）
-- 说明：保留原始查询口径与计算逻辑；各查询可按需单独执行。

use ecommerce_analysis;

select
    sum(payment_amount) as actual_sales
from order_master
where
    order_time between date_sub(curdate(), interval 30 day) and curdate()and payment_status = 'PAID';
