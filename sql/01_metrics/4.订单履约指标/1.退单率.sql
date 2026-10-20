-- 1.退单率
-- 指标说明：统计周期内，有退货记录的订单数占已支付订单数的比例
-- 说明：保留原始查询口径与计算逻辑；各查询可按需单独执行。

use ecommerce_analysis;

select
    pc.category_id,
    count(distinct case when od.is_return = 1 then o.order_id end) as return_orders,
    count(distinct o.order_id) as total_orders,
    round(count(distinct case when od.is_return = 1 then o.order_id end)
        / count(distinct o.order_id) * 100, 2) as return_rate
from order_master o
join order_detail od on o.order_id = od.order_id
join product_detail pd on od.product_id = pd.product_id
join product_category pc on pd.category_id = pc.category_id
where o.order_time between date_sub(curdate(), interval 30 day) and curdate()
group by pc.category_id
order by return_rate desc;
