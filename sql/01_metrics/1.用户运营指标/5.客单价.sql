# - 定义：统计周期内，平均每个付费用户的消费总金额，反映用户的消费能力和平台的 “用户价值挖掘能力”。
# - 核心作用：评估用户分层运营效果（如会员体系、满减活动），是营收增长的核心驱动指标（与 “付费用户数” 共同决定总营收）。
# - 计算逻辑：
# 数据来源：order_master表
# 公式：客单价 = 统计周期内所有已支付订单的payment_amount总和 / 付费用户数（去重）
# 涉及字段：payment_amount（实付金额）、user_id（付费用户）、payment_status='PAID'（有效订单）。
# - 结果字段示例：
#   - 统计周期：2025-06
#   - 总支付金额：280 万元
#   - 付费用户数：10,000 人
#   - 客单价：280 元
# - 理想结果：
#   - 整体客单价≥行业均值（如 250 元），且随用户生命周期提升：老用户客单价（350 元）＞新用户（200 元）。
#   - 会员用户客单价≥非会员的 1.5 倍（如会员 420 元 vs 非会员 280 元），体现会员体系价值。
# - 业务解读：
#   - 若客单价＜200 元，需通过 “提升单次消费金额” 优化（如推出 “满 300 减 50” 活动、组合套餐 “买 A 送 B”），或针对高价值用户推出专属权益（如会员价、限量款）。

use ecommerce_analysis;

select sum(payment_amount)/count(distinct user_id)
from order_master
where
    payment_status = 'PAID' and
    order_time between date_sub(curdate(), interval 30 day) and curdate();