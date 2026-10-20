-- 1.商品管理指标
-- 指标说明：统计周期内，商品销售数量与平均库存的比值
-- 说明：保留原始查询口径与计算逻辑；各查询可按需单独执行。

use ecommerce_analysis;
-- 近30天各分类库存周转率（后端/etl）
select
    pc.category_id,
    sum(pd.sales_count) as total_sales, -- 假设sales_count为30天销量（实际需关联订单明细）
    avg(pd.stock_quantity) as avg_stock,
    round(sum(pd.sales_count) / avg(pd.stock_quantity), 2) as inventory_turnover
from product_detail pd
join product_category pc on pd.category_id = pc.category_id
where pd.shelf_status = 1 -- 在售商品
group by pc.category_id
order by inventory_turnover desc;
