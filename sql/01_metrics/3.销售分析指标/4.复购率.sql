# - 定义：统计周期内，消费≥2 次的用户占总付费用户的比例，反映用户对平台的忠诚度（非 “一次性消费”）。
# - 核心作用：评估用户留存质量，复购率高意味着用户认可产品 / 服务，可降低获客成本（老用户复购成本＜新用户获客成本）。
# - 计算逻辑：
# 数据来源：order_master表
# 公式：复购率 = （消费≥2次的用户数 / 总付费用户数）× 100%
# 涉及字段：order_master.user_id（关联用户）、order_master.payment_status='PAID'（付费订单）。
# - 结果字段示例：
#   - 总付费用户数：8,000 人
#   - 消费≥2 次的用户数：2,800 人
#   - 复购率：35%
# - 理想结果：
#   - 整体复购率≥30%（电商行业均值），且老用户（注册≥6 个月）复购率≥40%。
#   - 高客单价用户复购率≥50%（核心用户忠诚度高）。
# - 业务解读：
#   - 若复购率＜20%：推出会员体系（如积分兑换、专属折扣）、定期推送个性化商品（基于历史购买记录），提升用户粘性。
-- 近30天用户复购率（消费≥2次的用户占比）
use ecommerce_analysis;


WITH user_purchase_counts AS (SELECT
        user_id,COUNT(DISTINCT order_id) AS order_count  -- 统计用户订单数（去重）
        FROM order_master
        WHERE order_time BETWEEN DATE_SUB(CURDATE(), INTERVAL 30 DAY) AND CURDATE()
        AND payment_status = 'PAID'  -- 仅统计已支付订单
        GROUP BY user_id
)
SELECT
    COUNT(DISTINCT user_id) AS total_paid_users,  -- 总付费用户数
    COUNT(DISTINCT CASE WHEN order_count >= 2 THEN user_id END) AS repurchase_users,  -- 复购用户数
    ROUND(COUNT(DISTINCT CASE WHEN order_count >= 2 THEN user_id END)
        / COUNT(DISTINCT user_id) * 100, 2) AS repurchase_rate  -- 复购率
        FROM user_purchase_counts;



