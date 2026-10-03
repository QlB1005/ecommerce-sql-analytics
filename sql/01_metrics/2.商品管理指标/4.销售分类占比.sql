# - 定义：某商品分类的销售额占总销售额的比例，反映平台的品类结构合理性。
# - 核心作用：评估品类布局是否均衡（非 “单品类依赖”），指导新品类拓展或旧品类优化。
# - 计算逻辑：
# 数据来源：product_category（分类信息）+ product_detail（商品 - 分类关联）+ order_detail（销售数据）
# 公式：分类销售占比 = （分类下所有商品的销售额总和 / 总销售额）× 100%
# 涉及字段：
#   - product_category.category_id、product_category.category_name（分类名称）；
#   - product_detail.category_id（关联分类）；
#   - order_detail.subtotal_amount（商品销售额，按product_id关联）。
# - 结果字段示例：
#   - 分类名称：女装
#   - 分类销售额：200 万元
#   - 总销售额：500 万元
#   - 分类销售占比：40%
# - 理想结果：
#   - 核心分类（如女装）占比≤50%（避免单品类依赖风险），且 3-5 个主力分类贡献 80% 以上销售额（结构集中但不单一）。
#   - 各分类同比增速差异＜20%（如女装增长 15%，男装增长 12%，差异 3%）。
# - 业务解读：
#   - 若某分类占比＞60%（如女装 65%）：拓展关联品类（如女装→配饰、鞋包），降低单一品类波动对整体营收的影响。
#   - 若某分类占比＜5% 且增速＜5%（如家居用品 3%）：评估是否为 “小众需求”，若长期无增长可收缩资源（如减少上新）。

use ecommerce_analysis;


-- 近30天各商品分类销售占比
WITH total_sales AS (SELECT SUM(subtotal_amount) AS total_amount
    FROM order_detail
    WHERE order_id IN (SELECT order_id FROM order_master
        WHERE order_time BETWEEN DATE_SUB(CURDATE(), INTERVAL 30 DAY) AND CURDATE())
        )
SELECT
    pc.category_id,
    SUM(od.subtotal_amount) AS category_amount,
  ROUND(SUM(od.subtotal_amount) / (SELECT total_amount FROM total_sales) * 100, 2) AS category_ratio
FROM order_detail od
JOIN product_detail pd ON od.product_id = pd.product_id
JOIN product_category pc ON pd.category_id = pc.category_id
JOIN order_master o ON od.order_id = o.order_id
WHERE o.order_time BETWEEN DATE_SUB(CURDATE(), INTERVAL 30 DAY) AND CURDATE() GROUP BY pc.category_id
ORDER BY category_amount DESC;


-- 近30天各商品分类销售占比
SELECT
    pd.category_id,
    SUM(od.subtotal_amount) AS category_amount,
    concat(ROUND(SUM(od.subtotal_amount) / SUM(SUM(od.subtotal_amount)) OVER() * 100, 2), '%') AS category_ratio
FROM order_detail od
left JOIN product_detail pd ON od.product_id = pd.product_id
left JOIN order_master o ON od.order_id = o.order_id
WHERE o.order_time BETWEEN DATE_SUB(CURDATE(), INTERVAL 30 DAY) AND CURDATE()
GROUP BY pd.category_id
ORDER BY category_amount DESC;
