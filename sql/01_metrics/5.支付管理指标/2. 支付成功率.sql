# - 定义：统计周期内，支付成功的订单数占支付尝试次数的比例，反映支付系统的稳定性（非用户主动放弃）。
# - 核心作用：评估支付接口的可靠性，支付成功率低会直接导致订单流失和用户不满。
# - 计算逻辑：
# 数据来源：payment_record表
# 公式：支付成功率 = （支付成功的订单数 / 支付尝试次数）× 100%
# 涉及字段：payment_record.order_id（关联订单）、payment_record.payment_status='SUCCESS'（支付成功）。
# - 结果字段示例：
#   - 支付尝试次数：10,000 次（含重复尝试）
#   - 支付成功次数：9,800 次
#   - 支付成功率：98%
# - 理想结果：
#   - 整体成功率≥95%，且各支付方式成功率差异＜3%（如微信 98% vs 支付宝 97%）。
#   - 无单日成功率＜90%（如接口故障导致）。
# - 业务解读：
#   - 若成功率＜95%：优先排查低成功率方式（如银行卡 90%），修复接口 bug、优化支付环境（如网络适配）。

use ecommerce_analysis;
SELECT
    COUNT(DISTINCT CASE WHEN payment_status = 'SUCCESS' THEN payment_id END) AS success_payments,
    COUNT(DISTINCT payment_id) AS total_payments,
    ROUND(COUNT(DISTINCT CASE WHEN payment_status = 'SUCCESS' THEN payment_id END)
        / COUNT(DISTINCT payment_id) * 100, 2) AS payment_success_rate
FROM payment_record
WHERE payment_time BETWEEN DATE_SUB(CURDATE(), INTERVAL 30 DAY) AND CURDATE();