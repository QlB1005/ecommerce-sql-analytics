-- 交易漏斗（90 天，7 日归因）
-- 分析截止日：2026-03-17
-- 路径：浏览 → 加购 → 下单 → 支付
-- 口径：行为发生在浏览之后，且间隔 ≤ 7 天

-- 1) 浏览 → 加购
WITH ll AS (
    SELECT COUNT(DISTINCT user_id) AS 浏览
    FROM traffic_log
    WHERE DATE(view_time) <= '2026-03-17'
      AND DATE(view_time) >= DATE_ADD('2026-03-17', INTERVAL -90 DAY)
),
jg AS (
    SELECT COUNT(DISTINCT u_b.user_id) AS 加购
    FROM traffic_log t_l
    JOIN user_behavior_event u_b
        ON t_l.user_id = u_b.user_id
       AND u_b.event_time >= t_l.view_time
       AND TIMESTAMPDIFF(DAY, t_l.view_time, u_b.event_time) <= 7
    WHERE u_b.event_type = 'ADD_TO_CART'
      AND DATE(t_l.view_time) <= '2026-03-17'
      AND DATE(t_l.view_time) >= DATE_ADD('2026-03-17', INTERVAL -90 DAY)
)
SELECT ROUND(jg.加购 / ll.浏览, 4) AS 浏览到加购
FROM jg, ll;

-- 2) 加购 → 下单
WITH jg AS (
    SELECT COUNT(DISTINCT u_b.user_id) AS 加购
    FROM traffic_log t_l
    JOIN user_behavior_event u_b
        ON t_l.user_id = u_b.user_id
       AND u_b.event_time >= t_l.view_time
       AND TIMESTAMPDIFF(DAY, t_l.view_time, u_b.event_time) <= 7
    WHERE u_b.event_type = 'ADD_TO_CART'
      AND DATE(t_l.view_time) <= '2026-03-17'
      AND DATE(t_l.view_time) >= DATE_ADD('2026-03-17', INTERVAL -90 DAY)
),
xd AS (
    SELECT COUNT(DISTINCT u_b.user_id) AS 下单
    FROM traffic_log t_l
    JOIN user_behavior_event u_b
        ON t_l.user_id = u_b.user_id
       AND u_b.event_time >= t_l.view_time
       AND TIMESTAMPDIFF(DAY, t_l.view_time, u_b.event_time) <= 7
    JOIN order_master o_m
        ON o_m.user_id = u_b.user_id
       AND o_m.order_time >= u_b.event_time
       AND TIMESTAMPDIFF(DAY, u_b.event_time, o_m.order_time) <= 7
    WHERE u_b.event_type = 'ADD_TO_CART'
      AND DATE(t_l.view_time) <= '2026-03-17'
      AND DATE(t_l.view_time) >= DATE_ADD('2026-03-17', INTERVAL -90 DAY)
)
SELECT ROUND(xd.下单 / jg.加购, 4) AS 加购到下单
FROM jg, xd;

-- 3) 下单 → 支付
WITH xd AS (
    SELECT COUNT(DISTINCT u_b.user_id) AS 下单
    FROM traffic_log t_l
    JOIN user_behavior_event u_b
        ON t_l.user_id = u_b.user_id
       AND u_b.event_time >= t_l.view_time
       AND TIMESTAMPDIFF(DAY, t_l.view_time, u_b.event_time) <= 7
    JOIN order_master o_m
        ON o_m.user_id = u_b.user_id
       AND o_m.order_time >= u_b.event_time
       AND TIMESTAMPDIFF(DAY, u_b.event_time, o_m.order_time) <= 7
    WHERE u_b.event_type = 'ADD_TO_CART'
      AND DATE(t_l.view_time) <= '2026-03-17'
      AND DATE(t_l.view_time) >= DATE_ADD('2026-03-17', INTERVAL -90 DAY)
),
zf AS (
    SELECT COUNT(DISTINCT u_b.user_id) AS 支付
    FROM traffic_log t_l
    JOIN user_behavior_event u_b
        ON t_l.user_id = u_b.user_id
       AND u_b.event_time >= t_l.view_time
       AND TIMESTAMPDIFF(DAY, t_l.view_time, u_b.event_time) <= 7
    JOIN order_master o_m
        ON o_m.user_id = u_b.user_id
       AND o_m.order_time >= u_b.event_time
       AND TIMESTAMPDIFF(DAY, u_b.event_time, o_m.order_time) <= 7
       AND o_m.payment_status = 'PAID'
    WHERE u_b.event_type = 'ADD_TO_CART'
      AND DATE(t_l.view_time) <= '2026-03-17'
      AND DATE(t_l.view_time) >= DATE_ADD('2026-03-17', INTERVAL -90 DAY)
)
SELECT ROUND(zf.支付 / xd.下单, 4) AS 下单到支付
FROM xd, zf;