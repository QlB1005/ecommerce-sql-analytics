-- 04_funnel.sql
-- 用户级漏斗：浏览后 7 日归因
-- 窗口与渠道 ROI、RFM 对齐：2025-12-17 ~ 2026-03-17
-- 浏览——加购
with ll as (
    select count(distinct user_id) 浏览
    from traffic_log
    where view_time >= '2025-12-17 00:00:00'
      and view_time <= '2026-03-17 23:59:59'
),
jg as (
    select count(distinct u_b.user_id) 加购
    from traffic_log t_l
    join user_behavior_event u_b on t_l.user_id = u_b.user_id
                                and u_b.event_time >= t_l.view_time
                                and timestampdiff(day, t_l.view_time, u_b.event_time) <= 7
    where u_b.event_type = 'ADD_TO_CART'
      and t_l.view_time >= '2025-12-17 00:00:00'
      and t_l.view_time <= '2026-03-17 23:59:59'
)
select round(jg.加购 / ll.浏览, 4) as 浏览——加购
from jg, ll;


-- 加购——下单  （下单不要筛 paid）
with jg as (
    select count(distinct u_b.user_id) 加购
    from traffic_log t_l
    join user_behavior_event u_b on t_l.user_id = u_b.user_id
                                and u_b.event_time >= t_l.view_time
                                and timestampdiff(day, t_l.view_time, u_b.event_time) <= 7
    where u_b.event_type = 'ADD_TO_CART'
      and t_l.view_time >= '2025-12-17 00:00:00'
      and t_l.view_time <= '2026-03-17 23:59:59'
),
xd as (
    select count(distinct u_b.user_id) 下单
    from traffic_log t_l
    join user_behavior_event u_b on t_l.user_id = u_b.user_id
                                and u_b.event_time >= t_l.view_time
                                and timestampdiff(day, t_l.view_time, u_b.event_time) <= 7
                                and u_b.event_type = 'ADD_TO_CART'
                                and t_l.view_time >= '2025-12-17 00:00:00'
                                and t_l.view_time <= '2026-03-17 23:59:59'
    join order_master o_m on o_m.user_id = u_b.user_id
                         and o_m.order_time >= u_b.event_time
                         and timestampdiff(day, u_b.event_time, o_m.order_time) <= 7
)
select round(xd.下单 / jg.加购, 4) as 加购——下单
from jg, xd;


-- 下单——支付  （只有支付筛 paid）
with xd as (
    select count(distinct u_b.user_id) 下单
    from traffic_log t_l
    join user_behavior_event u_b on t_l.user_id = u_b.user_id
                                and u_b.event_time >= t_l.view_time
                                and timestampdiff(day, t_l.view_time, u_b.event_time) <= 7
                                and u_b.event_type = 'ADD_TO_CART'
                                and t_l.view_time >= '2025-12-17 00:00:00'
                                and t_l.view_time <= '2026-03-17 23:59:59'
    join order_master o_m on o_m.user_id = u_b.user_id
                         and o_m.order_time >= u_b.event_time
                         and timestampdiff(day, u_b.event_time, o_m.order_time) <= 7
),
zf as (
    select count(distinct u_b.user_id) 支付
    from traffic_log t_l
    join user_behavior_event u_b on t_l.user_id = u_b.user_id
                                and u_b.event_time >= t_l.view_time
                                and timestampdiff(day, t_l.view_time, u_b.event_time) <= 7
                                and u_b.event_type = 'ADD_TO_CART'
                                and t_l.view_time >= '2025-12-17 00:00:00'
                                and t_l.view_time <= '2026-03-17 23:59:59'
    join order_master o_m on o_m.user_id = u_b.user_id
                         and o_m.order_time >= u_b.event_time
                         and timestampdiff(day, u_b.event_time, o_m.order_time) <= 7
                         and o_m.payment_status = 'paid'
)
select round(zf.支付 / xd.下单, 4) as 下单——支付
from xd, zf;