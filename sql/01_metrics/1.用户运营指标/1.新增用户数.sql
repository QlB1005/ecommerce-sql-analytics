# - 定义：特定统计周期内（如近 30 天），通过注册流程新增的用户总数（按用户 ID 去重）。(口径、维度、指标)
# - 核心作用：衡量企业拉新能力，评估营销活动、渠道推广的实际效果，是业务增长的基础指标。
# - 计算逻辑：
# 数据来源：user_master表
# 公式：新增用户数 = COUNT(DISTINCT user_id) WHERE register_time BETWEEN 统计周期的起止时间
# 涉及字段：user_id（用户唯一标识）、register_time（注册时间）。
# - 结果字段示例：
#   - 统计周期：2025-06-01 至 2025-06-30
#   - 新增用户数：3,200 人
#   - 每日新增趋势：最低 100 人 / 天，最高 150 人 / 天，周末略高于工作日
# - 理想结果：
#   - 整体趋势：月度环比增长≥10%，无连续 3 天的大幅下滑（如单日新增＜80 人）。
    # 目标: 求环比增长率 = (当前月新增人数 - 上一月新增人数) / 上一月新增人数 * 100
#   - 渠道分布：各核心渠道（如抖音、微信）均有稳定新增，单一渠道占比不超过 60%（避免渠道依赖风险）。
# - 业务解读：
#   - 若新增用户骤降，需排查渠道是否出现政策调整（如平台限流）、拉新活动是否暂停，或注册流程是否存在故障（如验证码失效）。
#   - 若某渠道新增异常高（如占比 70%），需结合后续 “渠道转化率” 判断是否为无效刷量（如新增用户无后续行为）。

use ecommerce_analysis;
SHOW TABLES;

#新增用户
select count(distinct user_id)新增用户数
from user_master
where register_time between date_add("2026-01-30",interval -30 day) and "2026-01-30";

# 月环比
    # 目标: 求环比增长率 = (当前月新增人数 - 上一月新增人数) / 上一月新增人数 * 100

with cur_month as(
    select count(distinct user_id) as cur_month
    from user_master
    where register_time between date_add("2026-01-31",interval -30 day ) and "2026-01-31"),
last_month as(
    select count(distinct user_id) as last_month
    from user_master
    where register_time between date_add("2025-12-31",interval -30 day) and "2025-12-31"
)
select round((cur_month.cur_month-last_month.last_month)/last_month.last_month*100,2) AS 环比增长率
from cur_month,last_month;


# 每月新增用户以与环比趋势
    # 目标: 求环比增长率 = (当前月新增人数 - 上一月新增人数) / 上一月新增人数 * 100
with month_users as(select date_format(register_time,'%Y-%m') register_time ,count(distinct user_id) new_month_users
    from user_master
    GROUP BY date_format(register_time,'%Y-%m'))
select register_time,
       concat(round((new_month_users-lag(new_month_users,1) over(order by register_time))/
              lag(new_month_users) over(order by register_time) *100,2),'%') as 月环比增长趋势
       from month_users;

# 各渠道新增用户
with channel_users as(
    select channel_source,count(distinct user_id) new_users
    from user_master
    where register_time between date_add("2026-01-31",interval -30 day) and "2026-01-31"
    group by channel_source
)








SELECT COUNT(DISTINCT user_id) AS 新增用户数
FROM user_master
WHERE register_time BETWEEN DATE_SUB(CURDATE(), INTERVAL 30 DAY) AND CURDATE();