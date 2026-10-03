# - 定义：统计周期内，各支付方式（如支付宝、微信）的交易金额占总支付金额的比例，反映用户的支付习惯。
# - 核心作用：指导支付渠道的资源投入（如与高占比渠道谈判费率优惠），确保支付方式覆盖主流需求。
# - 计算逻辑：
# 数据来源：payment_record表
# 公式：支付方式占比 = （某支付方式的交易金额 / 总支付金额）× 100%
# 涉及字段：payment_record.payment_method（支付方式）、payment_record.payment_amount（交易金额）。
# - 结果字段示例：
#   - 支付方式：微信支付
#   - 交易金额：300 万元
#   - 总支付金额：500 万元
#   - 占比：60%
# - 理想结果：
#   - 主流支付方式（微信、支付宝）合计占比≥90%（覆盖绝大多数用户），且无单一方式占比＞70%（避免依赖风险）。
#   - 新兴支付方式（如数字人民币）占比逐步提升（如从 1% 到 3%）。
# - 业务解读：
#   - 若某主流方式占比＜20%（如支付宝 30%）：检查是否为支付入口隐藏过深，或推出 “支付宝专享券” 引导使用（平衡比例）。

use ecommerce_analysis;

WITH total_payment AS (
SELECT SUM(payment_amount) AS total
FROM payment_record
    WHERE payment_time BETWEEN DATE_SUB(CURDATE(), INTERVAL 30 DAY) AND CURDATE()
)SELECT
    payment_method,
    SUM(payment_amount) AS method_amount,
    ROUND(SUM(payment_amount) / (SELECT total FROM total_payment) * 100, 2) AS method_ratio
FROM payment_record
WHERE payment_time BETWEEN DATE_SUB(CURDATE(), INTERVAL 30 DAY) AND CURDATE()
GROUP BY payment_method
ORDER BY method_amount DESC;