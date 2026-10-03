-- RFM 用户分层（90 天）
-- 分析截止日：2026-03-17
-- R：最近一次购买距截止日的天数
-- F：窗口内订单次数
-- M：按销售额从高到低累计，累计贡献 ≤80% 为高，≤95% 为中，其余为低
-- 注意：M 不是「人数前 20%」，而是「金额累计贡献」

DROP TABLE IF EXISTS RFM_90;

CREATE TABLE RFM_90 AS
WITH r_data AS (
    SELECT
        user_id,
        DATEDIFF('2026-03-17', MAX(payment_time)) AS r_value,
        CASE
            WHEN DATEDIFF('2026-03-17', MAX(payment_time)) <= 45 THEN '高'
            WHEN DATEDIFF('2026-03-17', MAX(payment_time)) <= 75 THEN '中'
            ELSE '低'
        END AS R
    FROM order_master
    WHERE payment_time <= '2026-03-17'
      AND payment_time >= DATE_ADD('2026-03-17', INTERVAL -90 DAY)
    GROUP BY user_id
),
f_data AS (
    SELECT
        user_id,
        COUNT(order_id) AS f_value,
        CASE
            WHEN COUNT(order_id) >= 3 THEN '高'
            WHEN COUNT(order_id) = 2 THEN '中'
            ELSE '低'
        END AS F
    FROM order_master
    WHERE payment_time <= '2026-03-17'
      AND payment_time >= DATE_ADD('2026-03-17', INTERVAL -90 DAY)
    GROUP BY user_id
),
m_data AS (
    WITH sum_temp AS (
        SELECT
            user_id,
            SUM(payment_amount) AS total_amount
        FROM order_master
        WHERE payment_time <= '2026-03-17'
          AND payment_time >= DATE_ADD('2026-03-17', INTERVAL -90 DAY)
        GROUP BY user_id
    ),
    ranked_temp AS (
        SELECT
            user_id,
            total_amount,
            SUM(total_amount) OVER (ORDER BY total_amount DESC)
                / (SELECT SUM(total_amount) FROM sum_temp) AS cum_percent
        FROM sum_temp
    )
    SELECT
        user_id,
        total_amount,
        CASE
            WHEN cum_percent <= 0.80 THEN '高'
            WHEN cum_percent <= 0.95 THEN '中'
            ELSE '低'
        END AS M
    FROM ranked_temp
)
SELECT
    r.user_id,
    r.R,
    r.r_value,
    f.F,
    f.f_value,
    m.M,
    m.total_amount,
    CONCAT(r.R, f.F, m.M) AS RFM_Code,
    CASE
        WHEN r.R = '高' AND f.F = '高' AND m.M = '高' THEN '重要价值客户 (VIP)'
        WHEN r.R = '高' AND f.F = '高' AND m.M = '低' THEN '重要发展客户 (需提客单)'
        WHEN r.R = '高' AND f.F = '低' AND m.M = '高' THEN '重要保持客户 (需维持)'
        WHEN r.R = '低' AND f.F = '高' AND m.M = '高' THEN '重要挽留客户 (需召回!)'
        WHEN r.R = '低' AND f.F = '低' AND m.M = '低' THEN '低价值客户 (路人)'
        ELSE '普通客户'
    END AS Customer_Tag
FROM r_data r
JOIN f_data f ON r.user_id = f.user_id
JOIN m_data m ON r.user_id = m.user_id;

SELECT
    Customer_Tag,
    ROUND(COUNT(DISTINCT user_id) / (SELECT COUNT(DISTINCT user_id) FROM RFM_90) * 100, 2) AS 标签人数占比,
    ROUND(SUM(total_amount) / (SELECT SUM(total_amount) FROM RFM_90) * 100, 2) AS 金额占比
FROM RFM_90
GROUP BY Customer_Tag
ORDER BY 金额占比 DESC;