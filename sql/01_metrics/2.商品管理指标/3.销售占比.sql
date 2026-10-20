-- 3.销售占比
-- 指标说明：单个 SKU 的销售额占总销售额的比例
-- 说明：保留原始查询口径与计算逻辑；各查询可按需单独执行。

-- 近30天销量前5的SKU占比
use ecommerce_analysis;

with total_sales as (
    select sum(purchase_quantity) as total_qty from order_detail
    where order_id in (
        select order_id from order_master
        where order_time between date_sub(curdate(), interval 30 day) and curdate()
    )
),
sku_sales as (
    select
        pd.sku_code,
        sum(od.purchase_quantity) as sku_qty
    from order_detail od
    join product_detail pd on od.product_id = pd.product_id
    join order_master o on od.order_id = o.order_id
    where o.order_time between date_sub(curdate(), interval 30 day) and curdate()
    group by pd.sku_code, pd.product_name
)
select
    sku_code,
    sku_qty,
    round(sku_qty / (select total_qty from total_sales) * 100, 2) as sales_ratio
from sku_sales
order by sku_qty desc
limit 5;

select
    pd.sku_code,
    sum(od.purchase_quantity) as total_qty,
    concat(round((sum(od.purchase_quantity)/sum(sum(od.purchase_quantity)) over())*100,2),"%") as sales_ratio
from order_detail od
left join product_detail pd on od.product_id = pd.product_id
left join order_master o on od.order_id = o.order_id
where o.order_time between date_sub(curdate(), interval 30 day) and curdate()
group by pd.sku_code
order by total_qty
limit 5;

select * from order_detail;
