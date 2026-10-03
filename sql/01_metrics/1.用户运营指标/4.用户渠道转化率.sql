# - 定义：某注册渠道的新增用户中，完成首单支付的用户比例，用于评估渠道的用户质量（非单纯 “拉新数量”）。
# - 核心作用：筛选高价值获客渠道，优化营销资源分配（优先投入高转化渠道），降低获客成本。
# - 计算逻辑：
# 数据来源：user_master（渠道信息）+ order_master（订单信息）
# 公式：渠道转化率 = （渠道新增用户中首单支付的用户数 / 渠道新增用户总数）× 100%
# 涉及字段：
#   - user_master.channel_source（注册渠道）、user_master.register_time（用于筛选新增用户）；
#   - order_master.user_id（关联用户）、order_master.payment_status='PAID'（首单支付状态）。
# - 结果字段示例：
#   - 渠道名称：抖音
#   - 渠道新增用户数：1,500 人
#   - 首单支付用户数：330 人
#   - 渠道转化率：22%
# - 理想结果：
#   - 核心渠道（抖音、微信）转化率≥15%，边缘渠道（如官网）≥5%，无渠道转化率＜3%（避免无效投入）。
#   - 渠道间转化率差异可控：最高与最低渠道的转化率比值＜5 倍（如抖音 22% vs 官网 5%，比值 4.4 倍）。
# - 业务解读：
#   - 高转化渠道（如抖音 22%）：加大投放预算，复制其引流策略（如短视频内容风格、落地页设计）。
#   - 低转化渠道（如官网 5%）：优化落地页体验（如增加 “立即购买” 按钮），或暂停投放（若长期无改善）。
use ecommerce_analysis;
show tables;



# 公式：渠道转化率 = （渠道新增用户中首单支付的用户数 / 渠道新增用户总数）× 100%
with new_user_pay as
    (select u_m.channel_source as 渠道,
#             p_d.brand 品牌,
           count(distinct u_m.user_id) as 新增用户首单支付用户数
    from user_master u_m
    join order_master o_m on u_m.user_id = o_m.user_id and
                             date(u_m.register_time)<='2026-03-17' and date(u_m.register_time)>= date_add('2026-03-17',interval -90 day) and
                              payment_status="Paid" and o_m.order_time >= u_m.register_time
#     join order_detail o_d on o_m.order_id=o_d.order_id
#     join product_detail p_d on o_d.product_id=p_d.product_id
    group by u_m.channel_source),
new_user as(
    select u_m.channel_source as 渠道,
    count(distinct u_m.user_id) as 新增用户总数
    from user_master u_m
    where      date(u_m.register_time)<='2026-03-17' and date(u_m.register_time)>= date_add('2026-03-17',interval -90 day)
    group by u_m.channel_source
),
brand as(
    select "品牌A" as 品牌 union all
                       select "品牌B" as 品牌 union all
                                          select "品牌C" as 品牌 union all
                                                             select "无品牌" as 品牌
)
,temp as (select
        n_u.渠道,
       新增用户总数,
       新增用户首单支付用户数,
       round(新增用户首单支付用户数/新增用户总数,2) as 渠道转化率
from new_user n_u
join new_user_pay n_p on n_u.渠道=n_p.渠道)
select * from temp cross join  brand
;









































WITH channel_new_users AS (SELECT
        channel_source,COUNT(DISTINCT user_id) AS new_user_count
    FROM user_master
    WHERE register_time BETWEEN DATE_SUB(CURDATE(), INTERVAL 30 DAY) AND CURDATE()
    GROUP BY channel_source
),
channel_paid_users AS (SELECT
        u.channel_source,COUNT(DISTINCT u.user_id) AS paid_user_count
    FROM user_master u
    JOIN order_master o ON u.user_id = o.user_id
    WHERE
        u.register_time BETWEEN DATE_SUB(CURDATE(), INTERVAL 30 DAY) AND CURDATE()
        AND o.payment_status = 'PAID'AND o.order_time >= u.register_time
    GROUP BY u.channel_source
)SELECT
    c.channel_source,
    c.new_user_count,
    p.paid_user_count,ROUND(p.paid_user_count / c.new_user_count * 100, 2) AS conversion_rate
FROM channel_new_users c
LEFT JOIN channel_paid_users p ON c.channel_source = p.channel_source;