-- 2.商品毛利润
-- 指标说明：商品毛利（售价 - 成本价）与售价的比例
-- 说明：保留原始查询口径与计算逻辑；各查询可按需单独执行。

use ecommerce_analysis;
select
    brand,round(avg((price - cost_price) / price * 100), 2) as gross_margin_rate
from product_detail
group by brand
order by gross_margin_rate desc;
