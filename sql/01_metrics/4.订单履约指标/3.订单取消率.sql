# - 定义：统计周期内，用户取消的未支付订单数占总下单数的比例，反映订单的 “有效性”（非 “恶意下单” 或 “误操作”）。
# - 核心作用：评估订单稳定性，减少无效订单对库存、物流的干扰（如虚假下单导致库存锁定）。
# - 计算逻辑：
# 数据来源：order_master表
# 公式：订单取消率 = （用户取消的未支付订单数 / 总下单数）× 100%
# 涉及字段：order_master.order_id、order_master.payment_status='UNPAID'（未支付）、order_master.order_time（用于判断 “超时未支付” 即取消）。
# - 结果字段示例：
#   - 总下单数：12,000 单
#   - 用户取消的未支付订单数：1,200 单
#   - 取消率：10%
# - 理想结果：
#   - 整体取消率≤15%，且 “超时未支付”（用户放弃）占比＜70%（非主要原因）。
#   - 大促期间取消率增幅＜5%（如平日 10%，大促 12%）。
# - 业务解读：
#   - 若取消率＞20%：排查是否为 “库存不足” 导致用户取消（如显示有货但下单后提示缺货），或优化下单流程（如增加 “确认订单” 弹窗减少误操作）。

use ecommerce_analysis;

-- 近30天订单取消率（未支付且超时未支付的订单占比）
SELECT
    COUNT(DISTINCT o.order_id) AS total_orders,  -- 总订单数
    COUNT(DISTINCT CASE
        WHEN o.payment_status = 'UNPAID'
        AND TIMESTAMPDIFF(HOUR, o.order_time, NOW()) > 24  -- 超过24小时未支付视为取消
        THEN o.order_id
    END) AS cancel_orders,  -- 取消订单数
    ROUND(COUNT(DISTINCT CASE
            WHEN o.payment_status = 'UNPAID'
            AND TIMESTAMPDIFF(HOUR, o.order_time, NOW()) > 24
            THEN o.order_id
        END) / COUNT(DISTINCT o.order_id) * 100, 2) AS cancel_rate  -- 取消率
FROM order_master o
WHERE o.order_time BETWEEN DATE_SUB(CURDATE(), INTERVAL 30 DAY) AND CURDATE();