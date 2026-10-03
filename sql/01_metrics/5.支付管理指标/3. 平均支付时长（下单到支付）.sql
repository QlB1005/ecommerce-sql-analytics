# - 定义：统计周期内，用户从 “下单” 到 “支付成功” 的平均时间，反映用户的支付决策速度。
# - 核心作用：评估用户对 “订单的迫切度” 或 “支付流程的便捷性”，时长过长可能导致订单流失（如用户遗忘）。
# - 计算逻辑：
# 数据来源：order_master（下单）+ payment_record（支付）
# 公式：平均支付时长 = 平均（支付成功时间 - 下单时间）（按分钟 / 小时计算）
# 涉及字段：
#   - order_master.order_id、order_master.order_time（下单时间）；
#   - payment_record.order_id（关联订单）、payment_record.payment_time（支付成功时间）。
# - 结果字段示例：
#   - 已支付订单数：9,600 单
#   - 总支付时长：48,000 分钟
#   - 平均支付时长：5 分钟
# - 理想结果：
#   - 整体平均时长≤15 分钟，且移动端＜PC 端（如 APP 5 分钟 vs PC 10 分钟，流程更便捷）。
#   - 大促期间时长增幅＜10%（用户决策未明显延迟）。
# - 业务解读：
#   - 若平均时长＞30 分钟：推出 “限时支付优惠”（如 “10 分钟内支付立减 10 元”），或优化支付页加载速度（减少等待时间）。

use ecommerce_analysis;

SELECT
    AVG(TIMESTAMPDIFF(MINUTE, order_time, payment_time)) AS avg_payment_minutes
FROM order_master
WHERE
    order_time BETWEEN DATE_SUB(CURDATE(), INTERVAL 30 DAY) AND CURDATE()
    AND payment_status = 'PAID';