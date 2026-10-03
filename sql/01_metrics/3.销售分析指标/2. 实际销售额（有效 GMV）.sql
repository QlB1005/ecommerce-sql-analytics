# - 定义：统计周期内已支付订单的总金额（剔除未支付、已取消、已退款订单），反映企业的真实营收（可确认收入）。
# - 核心作用：衡量企业的盈利能力，是财务核算、利润分析的核心指标（区别于 “GMV” 的 “虚增规模”）。
# - 计算逻辑：
# 数据来源：order_master表
# 公式：实际销售额 = SUM(payment_amount) WHERE payment_status='PAID' AND order_time BETWEEN 统计周期的起止时间
# 涉及字段：order_master.payment_amount（实付金额）、order_master.payment_status（支付状态）、order_master.order_time。
# - 结果字段示例：
#   - 统计周期：2025 年 6 月
#   - 实际销售额：500 万元
#   - 其中：新用户贡献 150 万元，老用户贡献 350 万元
# - 理想结果：
#   - 实际销售额与 GMV 的比值≥85%（支付转化率高），且老用户贡献占比≥60%（用户留存带来稳定收入）。
#   - 月度同比增速≥15%（营收健康增长）。
# - 业务解读：
#   - 若销售额增速＜GMV 增速（如 GMV 增长 20%，销售额增长 10%）：支付转化率下降，需优化支付环节（如简化步骤、修复支付失败 bug）。
use ecommerce_analysis;


SELECT
    SUM(payment_amount) AS actual_sales
FROM order_master
WHERE
    order_time BETWEEN DATE_SUB(CURDATE(), INTERVAL 30 DAY) AND CURDATE()AND payment_status = 'PAID';