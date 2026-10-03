# - 定义：统计周期内所有订单的总金额（含未支付、已取消、已退款订单），反映平台的交易规模和市场影响力。
# - 核心作用：衡量业务整体活跃度，是企业规模扩张的核心指标（尤其在成长期）。
# - 计算逻辑：
# 数据来源：order_master表
# 公式：GMV = SUM(total_amount) WHERE order_time BETWEEN 统计周期的起止时间
# 涉及字段：order_master.total_amount（订单总金额）、order_master.order_time（订单时间）。
# - 结果字段示例：
#   - 统计周期：2025 年 6 月
#   - GMV：600 万元
#   - 每日 GMV 趋势：周末峰值达 25 万元 / 天，工作日平均 18 万元 / 天
# - 理想结果：
#   - 同比增速≥20%（反映市场份额扩张），且 GMV 与实际销售额（已支付）的比值≤1.2（未支付订单占比低，交易质量高）。
#   - 无单日 GMV 环比下滑＞30%（如从 20 万元跌至 12 万元，需排查是否为系统故障）。
# - 业务解读：
#   - 若 GMV 高但实际销售额低（比值＞1.3）：未支付订单占比过高，需优化支付流程（如减少跳转、支持多种支付方式）或降低 “冲动下单”（如商品详情页明确标注 “不支持 7 天无理由”）。
use ecommerce_analysis;

SELECT
    DATE(order_time) AS order_date,
    SUM(total_amount) AS daily_gmv
FROM order_master
WHERE order_time BETWEEN DATE_SUB(CURDATE(), INTERVAL 30 DAY) AND CURDATE()
GROUP BY DATE(order_time)
ORDER BY order_date;