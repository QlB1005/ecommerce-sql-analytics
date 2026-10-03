# - 定义：单个 SKU 的销售额占总销售额的比例，用于识别 “爆款”（高占比）和 “滞销品”（低占比）。
# - 核心作用：指导库存备货（爆款多备货）和商品下架（滞销品清仓后下架），优化 SKU 结构（避免冗余）。
# - 计算逻辑：
# 数据来源：product_detail（SKU 信息）+ order_detail（销售数据）
# 公式：SKU销售占比 = （单个SKU的销售额 / 总销售额）× 100%
# 涉及字段：
#   - product_detail.sku_code（SKU 唯一标识）、product_detail.product_id（关联商品）；
#   - order_detail.subtotal_amount（SKU 销售额，按product_id关联）。
# - 结果字段示例：
#   - SKU 编码：SKU0000000001
#   - 商品名称：夏季连衣裙（黑色）
#   - SKU 销售额：50 万元
#   - 总销售额：500 万元
#   - SKU 销售占比：10%
# - 理想结果：
#   - Top5 SKU 销售占比≤30%（避免 “单品依赖” 风险，如某 SKU 断货导致整体营收下滑）。
#   - 无 SKU 销售占比＜0.1%（如某 SKU 仅售 100 元，占比 0.02%，需下架）。
# - 业务解读：
#   - 若 Top1 SKU 占比＞15%（如 10% 接近临界值）：开发同款不同规格的 SKU（如增加颜色、尺码），分散风险。
#   - 若某 SKU 占比＜0.1%：启动清仓（如 “9.9 元秒杀”），清仓后下架，释放库存和运营资源。
-- 近30天销量前5的SKU占比
use ecommerce_analysis;


WITH total_sales AS (
    SELECT SUM(purchase_quantity) AS total_qty FROM order_detail
    WHERE order_id IN (
        SELECT order_id FROM order_master
        WHERE order_time BETWEEN DATE_SUB(CURDATE(), INTERVAL 30 DAY) AND CURDATE()
    )
),
sku_sales AS (
    SELECT
        pd.sku_code,
        SUM(od.purchase_quantity) AS sku_qty
    FROM order_detail od
    JOIN product_detail pd ON od.product_id = pd.product_id
    JOIN order_master o ON od.order_id = o.order_id
    WHERE o.order_time BETWEEN DATE_SUB(CURDATE(), INTERVAL 30 DAY) AND CURDATE()
    GROUP BY pd.sku_code, pd.product_name
)
SELECT
    sku_code,
    sku_qty,
    ROUND(sku_qty / (SELECT total_qty FROM total_sales) * 100, 2) AS sales_ratio
FROM sku_sales
ORDER BY sku_qty DESC
LIMIT 5;



SELECT
    pd.sku_code,
    SUM(od.purchase_quantity) AS total_qty,
    concat(round((SUM(od.purchase_quantity)/SUM(SUM(od.purchase_quantity)) OVER())*100,2),"%") AS sales_ratio
FROM order_detail od
left JOIN product_detail pd ON od.product_id = pd.product_id
left JOIN order_master o ON od.order_id = o.order_id
WHERE o.order_time BETWEEN DATE_SUB(CURDATE(), INTERVAL 30 DAY) AND CURDATE()
GROUP BY pd.sku_code
order by total_qty
limit 5;

select * from order_detail;
