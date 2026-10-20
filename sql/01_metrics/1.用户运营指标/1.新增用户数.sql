-- 1.新增用户数
-- 指标说明：特定统计周期内（如近 30 天），通过注册流程新增的用户总数（按用户 ID 去重）。(口径、维度、指标)
-- 说明：保留原始查询口径与计算逻辑；各查询可按需单独执行。

use ecommerce_analysis;
show tables;

-- 新增用户
select count(distinct user_id)新增用户数
from user_master
where register_time between date_add("2026-01-30",interval -30 day) and "2026-01-30";

-- 月环比

with cur_month as(
    select count(distinct user_id) as cur_month
    from user_master
    where register_time between date_add("2026-01-31",interval -30 day ) and "2026-01-31"),
last_month as(
    select count(distinct user_id) as last_month
    from user_master
    where register_time between date_add("2025-12-31",interval -30 day) and "2025-12-31"
)
select round((cur_month.cur_month-last_month.last_month)/last_month.last_month*100,2) as 环比增长率
from cur_month,last_month;

-- 每月新增用户以与环比趋势
with month_users as(select date_format(register_time,'%Y-%m') register_time ,count(distinct user_id) new_month_users
    from user_master
    group by date_format(register_time,'%Y-%m'))
select register_time,
       concat(round((new_month_users-lag(new_month_users,1) over(order by register_time))/
              lag(new_month_users) over(order by register_time) *100,2),'%') as 月环比增长趋势
       from month_users;

-- 各渠道新增用户
with channel_users as(
    select channel_source,count(distinct user_id) new_users
    from user_master
    where register_time between date_add("2026-01-31",interval -30 day) and "2026-01-31"
    group by channel_source
)

select count(distinct user_id) as 新增用户数
from user_master
where register_time between date_sub(curdate(), interval 30 day) and curdate();
