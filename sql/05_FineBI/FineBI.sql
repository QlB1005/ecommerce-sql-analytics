-- 05_FineBI.sql
-- FineBI 渠道与用户看板
-- 口径和 02_channel_roi / rfm_90 对齐：paid，order_time，注册渠道
-- 渠道支付用户数 = 窗内 paid 用户按注册渠道（含老用户）
-- 留存 = 窗内支付 >= 2 次
-- 周趋势标 2026-02-17 春节（前一周节前，当周春节）
-- 月度支付用户数只统计分析窗，12 月和 3 月是残月
-- 设备只统计本窗 paid 用户，不要拉历史 1.3 万人


-- 对账，先跑
select count(distinct o_m.order_id) as 单数,
       count(distinct o_m.user_id) as 人数,
       count(distinct u_m.channel_source) as 渠道数
from order_master o_m
join user_master u_m on o_m.user_id = u_m.user_id
where o_m.payment_status = 'paid'
  and o_m.order_time >= '2025-12-17 00:00:00'
  and o_m.order_time <= '2026-03-17 23:59:59';


-- kpi
create table kpi
with t_user as (
    select o_m.user_id,
           count(distinct o_m.order_id) as 单数
    from order_master o_m
    where o_m.payment_status = 'paid'
      and o_m.order_time >= '2025-12-17 00:00:00'
      and o_m.order_time <= '2026-03-17 23:59:59'
    group by o_m.user_id
)
select count(*) as 人数,
       sum(单数) as 单数,
       round(sum(case when 单数 >= 2 then 1 else 0 end) / count(*), 4) as 窗内复购率
from t_user;
select * from kpi;

-- 渠道支付用户 vs 窗内复购
create table 渠道新增与留存
with t_user as (
    select o_m.user_id,
           u_m.channel_source,
           count(distinct o_m.order_id) as 单数,
           sum(o_m.payment_amount) as gmv
    from order_master o_m
    join user_master u_m on o_m.user_id = u_m.user_id
    where o_m.payment_status = 'paid'
      and o_m.order_time >= '2025-12-17 00:00:00'
      and o_m.order_time <= '2026-03-17 23:59:59'
    group by o_m.user_id, u_m.channel_source
)
select channel_source as 渠道,
       count(*) as 支付用户数,
       sum(case when 单数 >= 2 then 1 else 0 end) as 复购人数,
       round(sum(case when 单数 >= 2 then 1 else 0 end) / count(*), 4) as 复购率,
       sum(单数) as 单数,
       round(sum(gmv), 2) as gmv
from t_user
group by channel_source
order by 支付用户数 desc;



-- 周趋势，春节标注
create table 周趋势
with t_week as (
    select date_sub(date(o_m.order_time), interval weekday(date(o_m.order_time)) day) as 周起始,
           o_m.order_id,
           o_m.user_id,
           o_m.payment_amount
    from order_master o_m
    where o_m.payment_status = 'paid'
      and o_m.order_time >= '2025-12-17 00:00:00'
      and o_m.order_time <= '2026-03-17 23:59:59'
)
select 周起始,
       case
           when 周起始 = '2026-02-09' then '春节前夕'
           when 周起始 = '2026-02-16' then '春节期间'
           else null
       end as 春节标记,
       count(distinct order_id) as 单数,
       count(distinct user_id) as 人数,
       round(sum(payment_amount), 2) as gmv
from t_week
group by 周起始
order by 周起始;
select * from 周趋势;



-- 月度支付用户数（保留原结果表名“月活”，避免影响现有 FineBI 引用）
create table 月活
with t_month as (
    select date_format(o_m.order_time, '%Y-%m') as 月份,
           o_m.user_id
    from order_master o_m
    where o_m.payment_status = 'paid'
      and o_m.order_time >= '2025-12-17 00:00:00'
      and o_m.order_time <= '2026-03-17 23:59:59'
)
select 月份,
       case
           when 月份 in ('2025-12', '2026-03') then '残月'
           else '整月'
       end as 月份类型,
       count(distinct user_id) as 月度支付用户数
from t_month
group by 月份
order by 月份;


-- 设备，只统计本窗 paid 用户
-- 把 device_type 换成你表里的列名
create table 设备
with t_user as (
    select o_m.user_id,
           max(u_m.device_type) as device_type
    from order_master o_m
    join user_master u_m on o_m.user_id = u_m.user_id
    where o_m.payment_status = 'paid'
      and o_m.order_time >= '2025-12-17 00:00:00'
      and o_m.order_time <= '2026-03-17 23:59:59'
    group by o_m.user_id
)
select device_type as 设备,
       count(*) as 人数,
       round(count(*) / (select count(*) from t_user), 4) as 占比
from t_user
group by device_type
order by 人数 desc;