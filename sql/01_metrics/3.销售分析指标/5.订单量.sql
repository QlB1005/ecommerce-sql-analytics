# - 定义：统计周期内的总下单数（含未支付、已取消），反映销售的 “活跃度”（非 “金额” 维度）。
# - 核心作用：衡量平台的交易频次，是评估促销活动效果（如 “618” 订单量激增）、仓储物流压力的基础指标。
# - 计算逻辑：
# 数据来源：order_master表
# 公式：订单量 = COUNT(order_id) WHERE order_time BETWEEN 统计周期的起止时间
# 涉及字段：order_master.order_id、order_master.order_time。
# - 结果字段示例：
#   - 统计周期：2025-06-18（618 大促）
#   - 当日订单量：30,000 单钱
#   - 较平日均值（12,000 单）增长：150%
# - 理想结果：
#   - 订单量与销售额趋势一致（如同步增长），无 “订单量增长但销售额下降”（如低价商品订单占比过高）。
#   - 大促期间订单量峰值＜仓储物流承载上限（如上限 50,000 单，实际 30,000 单）。
# - 业务解读：
#   - 若订单量增长但客单价下降：可能是 “低价引流” 活动导致，需平衡 “订单量” 与 “利润”（如限制低价商品的购买数量）。

use ecommerce_analysis;

SELECT
    DATE(order_time) AS order_date,
    COUNT(order_id) AS daily_orders
FROM order_master
WHERE order_time BETWEEN DATE_SUB(CURDATE(), INTERVAL 30 DAY) AND CURDATE()
GROUP BY DATE(order_time)ORDER BY order_date;