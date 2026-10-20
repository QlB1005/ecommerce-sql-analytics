-- 1.支付方式占比
-- 指标说明：统计周期内，各支付方式（如支付宝、微信）的交易金额占总支付金额的比例
-- 说明：保留原始查询口径与计算逻辑；各查询可按需单独执行。

use ecommerce_analysis;

with total_payment as (
select sum(payment_amount) as total
from payment_record
    where payment_time between date_sub(curdate(), interval 30 day) and curdate()
)select
    payment_method,
    sum(payment_amount) as method_amount,
    round(sum(payment_amount) / (select total from total_payment) * 100, 2) as method_ratio
from payment_record
where payment_time between date_sub(curdate(), interval 30 day) and curdate()
group by payment_method
order by method_amount desc;
