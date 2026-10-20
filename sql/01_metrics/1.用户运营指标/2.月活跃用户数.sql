-- 2.月活跃用户数
-- 指标说明：自然月内有登录行为的用户总数（按用户 ID 去重）
-- 说明：保留原始查询口径与计算逻辑；各查询可按需单独执行。

use ecommerce_analysis;
-- - 结果字段示例：
-- - 月活跃用户数：85,000 人
-- - 活跃率：42.5%（月活用户 / 总注册用户 200,000 人）
-- - 设备分布：APP 端占比 70%，H5 端 20%，PC 端 10%

select
    date_format(last_login_time,'%Y-%m') 统计月份,
       count(distinct user_id) 月活跃用户数,
       concat(round(count(distinct user_id)/(select count(distinct user_id) from user_master)*100,2),"%") 活跃率
from user_master
where last_login_time between "2024-01-01" and "2026-02-28"
group by date_format(last_login_time,'%Y-%m');

select date_format(last_login_time,"%Y-%m") 统计月份,
        device_type,
        count(user_id) 各设备登录
 from user_master
 where last_login_time between "2024-01-01" and "2026-02-28"
 group by date_format(last_login_time,'%Y-%m'), device_type
order by 统计月份;

select count(distinct user_id) as 月活跃用户数
from user_master
where last_login_time between date_sub(curdate(), interval 30 day) and curdate();
