# - 定义：统计周期内，订单从 “支付成功” 到 “用户签收” 的平均时长，反映物流配送效率。
# - 核心作用：评估物流体验（用户对 “到货速度” 的敏感度高），是提升用户满意度的关键指标。
# - 计算逻辑：
# 数据来源：order_master表
# 公式：平均订单时效 = 平均（签收时间 - 支付时间）（按小时 / 天计算）
# 涉及字段：order_master.payment_time（支付成功时间）、order_master.receive_time（用户签收时间）。
# - 结果字段示例：
#   - 统计订单数：8,000 单（已支付且签收）
#   - 总时长：48,000 小时
#   - 平均订单时效：6 小时（如 “当日达”“次日达” 订单占比高）
# - 理想结果：
#   - 平均时效≤48 小时（2 天），且 80% 订单时效≤72 小时（3 天）。
#   - 同城订单时效≤24 小时，跨省订单≤72 小时（符合用户预期）。
# - 业务解读：
#   - 若时效＞72 小时：优化仓储布局（如增加区域仓）、与物流公司签订 “时效保障协议”，或针对偏远地区提前告知时效（管理用户预期）。

use ecommerce_analysis;

SELECT
    AVG(TIMESTAMPDIFF(HOUR, payment_time, receive_time)) AS avg_delivery_hours
FROM order_master
WHERE
    order_time BETWEEN DATE_SUB(CURDATE(), INTERVAL 30 DAY) AND CURDATE()AND payment_status = 'PAID' AND receive_time IS NOT NULL;














