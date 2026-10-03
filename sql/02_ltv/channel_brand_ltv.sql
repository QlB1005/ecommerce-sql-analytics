-- 渠道 × 品牌 观测型 LTV
-- 分析截止日：2026-03-17（90 天窗口）
-- 口径：LTV = 客单价 × 毛利率 × 人均购买频次 × 渠道转化率
-- 说明：客单 / 毛利 / 频次是「渠道 × 品牌」；转化率是渠道级，再交叉到品牌

WITH ke_avg AS (
    SELECT
        u_m.channel_source AS 渠道,
        p_d.brand AS 品牌,
        ROUND(SUM(o_m.payment_amount) / COUNT(o_d.order_id), 2) AS 客单价
    FROM order_master o_m
    JOIN order_detail o_d
        ON o_m.order_id = o_d.order_id
    JOIN product_detail p_d
        ON o_d.product_id = p_d.product_id
    JOIN user_master u_m
        ON o_m.user_id = u_m.user_id
    WHERE DATE(o_m.payment_time) <= '2026-03-17'
      AND DATE(o_m.payment_time) >= DATE_ADD('2026-03-17', INTERVAL -90 DAY)
      AND o_m.payment_status = 'PAID'
      AND DATE(u_m.register_time) <= '2026-03-17'
      AND DATE(u_m.register_time) >= DATE_ADD('2026-03-17', INTERVAL -90 DAY)
    GROUP BY u_m.channel_source, p_d.brand
),
maoli AS (
    SELECT
        u_m.channel_source AS 渠道,
        p_d.brand AS 品牌,
        (SUM(p_d.price * (o_m.payment_amount / o_m.total_amount) * o_d.purchase_quantity)
       - SUM(p_d.cost_price * o_d.purchase_quantity))
       / SUM(p_d.price * (o_m.payment_amount / o_m.total_amount) * o_d.purchase_quantity) AS 毛利率
    FROM order_detail o_d
    JOIN product_detail p_d
        ON o_d.product_id = p_d.product_id
    JOIN order_master o_m
        ON o_d.order_id = o_m.order_id
    JOIN user_master u_m
        ON o_m.user_id = u_m.user_id
    WHERE DATE(o_m.payment_time) <= '2026-03-17'
      AND DATE(o_m.payment_time) >= DATE_ADD('2026-03-17', INTERVAL -90 DAY)
      AND o_m.payment_status = 'PAID'
    GROUP BY u_m.channel_source, p_d.brand
),
people_purchase AS (
    SELECT
        u_m.channel_source AS 渠道,
        p_d.brand AS 品牌,
        ROUND(COUNT(o_m.order_id) / COUNT(DISTINCT o_m.user_id), 2) AS 人均购买频次
    FROM order_master o_m
    JOIN user_master u_m
        ON o_m.user_id = u_m.user_id
    JOIN order_detail o_d
        ON o_m.order_id = o_d.order_id
    JOIN product_detail p_d
        ON o_d.product_id = p_d.product_id
    WHERE DATE(o_m.payment_time) <= '2026-03-17'
      AND DATE(o_m.payment_time) >= DATE_ADD('2026-03-17', INTERVAL -90 DAY)
      AND o_m.payment_status = 'PAID'
      AND DATE(u_m.register_time) <= '2026-03-17'
      AND DATE(u_m.register_time) >= DATE_ADD('2026-03-17', INTERVAL -90 DAY)
    GROUP BY u_m.channel_source, p_d.brand
),
new_user_pay AS (
    SELECT
        u_m.channel_source AS 渠道,
        COUNT(DISTINCT u_m.user_id) AS 新增用户首单支付用户数
    FROM user_master u_m
    JOIN order_master o_m
        ON u_m.user_id = o_m.user_id
    WHERE DATE(u_m.register_time) <= '2026-03-17'
      AND DATE(u_m.register_time) >= DATE_ADD('2026-03-17', INTERVAL -90 DAY)
      AND o_m.payment_status = 'PAID'
      AND o_m.order_time >= u_m.register_time
    GROUP BY u_m.channel_source
),
new_user AS (
    SELECT
        u_m.channel_source AS 渠道,
        COUNT(DISTINCT u_m.user_id) AS 新增用户总数
    FROM user_master u_m
    WHERE DATE(u_m.register_time) <= '2026-03-17'
      AND DATE(u_m.register_time) >= DATE_ADD('2026-03-17', INTERVAL -90 DAY)
    GROUP BY u_m.channel_source
),
brand AS (
    SELECT '品牌 A' AS 品牌
    UNION ALL SELECT '品牌 B'
    UNION ALL SELECT '品牌 C'
    UNION ALL SELECT '无品牌'
),
tran AS (
    SELECT
        n_u.渠道,
        b.品牌,
        ROUND(n_p.新增用户首单支付用户数 / n_u.新增用户总数, 2) AS 渠道转化率
    FROM new_user n_u
    JOIN new_user_pay n_p
        ON n_u.渠道 = n_p.渠道
    CROSS JOIN brand b
)
SELECT
    ke_avg.渠道,
    ke_avg.品牌,
    ROUND(ke_avg.客单价 * maoli.毛利率 * people_purchase.人均购买频次 * tran.渠道转化率, 2) AS LTV
FROM ke_avg
JOIN maoli
    ON ke_avg.渠道 = maoli.渠道
   AND ke_avg.品牌 = maoli.品牌
JOIN people_purchase
    ON ke_avg.渠道 = people_purchase.渠道
   AND ke_avg.品牌 = people_purchase.品牌
JOIN tran
    ON ke_avg.渠道 = tran.渠道
   AND ke_avg.品牌 = tran.品牌
ORDER BY LTV DESC;
