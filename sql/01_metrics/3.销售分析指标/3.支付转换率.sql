# - 定义：统计周期内，已支付订单数占总下单数的比例，反映用户从 “下单” 到 “支付” 的转化效率。
# - 核心作用：评估支付环节的体验（如流程复杂度、支付方式是否便捷），是减少 “订单流失” 的关键指标。
# - 计算逻辑：
# 数据来源：order_master表
# 公式：支付转化率 = （已支付订单数 / 总下单数）× 100%
# 涉及字段：order_master.order_id（订单唯一标识）、order_master.payment_status='PAID'（已支付订单）。
# - 结果字段示例：
#   - 总下单数：12,000 单
#   - 已支付订单数：9,600 单
#   - 支付转化率：80%
# - 理想结果：
#   - 整体支付转化率≥75%（行业均值），且移动端（APP/H5）转化率≥PC 端（如 APP 82% vs PC 70%）。
#   - 无单日转化率＜70%（如大促期间因系统卡顿导致转化率骤降）。
# - 业务解读：
#   - 若转化率＜70%：优化支付流程（如减少跳转步骤）、增加支付方式（如新增 “微信分付”），或针对未支付订单推送 “催付券”（如 “未支付订单立减 20 元”）。
use ecommerce_analysis;


SELECT
    COUNT(DISTINCT CASE WHEN payment_status = 'PAID' THEN order_id END) AS paid_orders,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(COUNT(DISTINCT CASE WHEN payment_status = 'PAID' THEN order_id END)
        / COUNT(DISTINCT order_id) * 100, 2) AS payment_conversion_rate
FROM order_master
WHERE order_time BETWEEN DATE_SUB(CURDATE(), INTERVAL 30 DAY) AND CURDATE();