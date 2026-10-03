# - 定义：统计周期内，有退货记录的订单数占已支付订单数的比例，反映商品质量、物流体验或描述一致性。
# - 核心作用：评估履约环节的质量（非 “卖出去即结束”），退货率高会增加成本（如逆向物流、退款）并损害用户信任。
# - 计算逻辑：
# 数据来源：order_master（订单）+ order_detail（退货明细）
# 公式：退货率 = （有退货的订单数 / 已支付订单数）× 100%
# 涉及字段：
#   - order_master.order_id、order_master.payment_status='PAID'（已支付订单）；
#   - order_detail.order_id（关联订单）、order_detail.is_return=1（有退货记录）。
# - 结果字段示例：
#   - 已支付订单数：9,600 单
#   - 有退货的订单数：480 单
#   - 退货率：5%
# - 理想结果：
#   - 整体退货率≤8%（电商行业均值），且各分类退货率差异不大：服饰类＜10%（尺码问题多），美妆类＜5%（质量问题敏感）。
#   - 退货原因中，“商品质量” 占比＜30%（非核心问题）。
# - 业务解读：
#   - 若退货率＞10%：优先排查高退货分类（如服饰 15%），优化商品描述（如增加尺码表精度）、提升质检标准，或推出 “退货险” 降低用户退货门槛（减少负面体验）。

use ecommerce_analysis;

SELECT
    pc.category_id,
    COUNT(DISTINCT CASE WHEN od.is_return = 1 THEN o.order_id END) AS return_orders,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(COUNT(DISTINCT CASE WHEN od.is_return = 1 THEN o.order_id END)
        / COUNT(DISTINCT o.order_id) * 100, 2) AS return_rate
FROM order_master o
JOIN order_detail od ON o.order_id = od.order_id
JOIN product_detail pd ON od.product_id = pd.product_id
JOIN product_category pc ON pd.category_id = pc.category_id
WHERE o.order_time BETWEEN DATE_SUB(CURDATE(), INTERVAL 30 DAY) AND CURDATE()
GROUP BY pc.category_id
ORDER BY return_rate DESC;