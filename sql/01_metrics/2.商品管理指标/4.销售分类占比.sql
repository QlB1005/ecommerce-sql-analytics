-- 4.销售分类占比
-- 指标说明：某商品分类的销售额占总销售额的比例
-- 说明：保留原始查询口径与计算逻辑；各查询可按需单独执行。

use ecommerce_analysis;

-- 近30天各商品分类销售占比
with total_sales as (select sum(subtotal_amount) as total_amount
    from order_detail
    where order_id in (select order_id from order_master
        where order_time between date_sub(curdate(), interval 30 day) and curdate())
        )
select
    pc.category_id,
    sum(od.subtotal_amount) as category_amount,
  round(sum(od.subtotal_amount) / (select total_amount from total_sales) * 100, 2) as category_ratio
from order_detail od
join product_detail pd on od.product_id = pd.product_id
join product_category pc on pd.category_id = pc.category_id
join order_master o on od.order_id = o.order_id
where o.order_time between date_sub(curdate(), interval 30 day) and curdate() group by pc.category_id
order by category_amount desc;

-- 近30天各商品分类销售占比
select
    pd.category_id,
    sum(od.subtotal_amount) as category_amount,
    concat(round(sum(od.subtotal_amount) / sum(sum(od.subtotal_amount)) over() * 100, 2), '%') as category_ratio
from order_detail od
left join product_detail pd on od.product_id = pd.product_id
left join order_master o on od.order_id = o.order_id
where o.order_time between date_sub(curdate(), interval 30 day) and curdate()
group by pd.category_id
order by category_amount desc;
