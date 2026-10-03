# - 定义：自然月内有登录行为的用户总数（按用户 ID 去重），反映平台的用户粘性和活跃度。
# - 核心作用：评估用户对平台的持续关注度，是衡量产品健康度的核心指标，直接影响后续转化和营收。
# - 计算逻辑：
# 数据来源：user_master表
# 公式：月活跃用户数 = COUNT(DISTINCT user_id) WHERE last_login_time BETWEEN 当月1日 AND 当月最后1日
# 涉及字段：user_id、last_login_time（最后登录时间）。
# - 结果字段示例：
#   - 统计月份：2025 年 6 月
#   - 月活跃用户数：85,000 人
#   - 活跃率：42.5%（月活用户 / 总注册用户 200,000 人）
#   - 设备分布：APP 端占比 70%，H5 端 20%，PC 端 10%
# - 理想结果：
#   - 活跃率≥40%（电商行业均值），且老用户（注册≥3 个月）占比≥60%（说明留存效果良好）。
#   - 活跃用户中，每周登录≥3 次的高频用户占比≥30%（用户粘性高）。
# - 业务解读：
#   - 若月活下降超过 10%，需分析是否为竞品分流、产品功能退化（如卡顿），或缺乏用户召回活动（如老用户专属优惠券）。
#   - 设备分布异常（如 PC 端占比＜5%）时，需优化对应端的体验（如 PC 端页面适配）。

use ecommerce_analysis;
# - 结果字段示例：
#   - 统计月份：2025 年 6 月
#   - 月活跃用户数：85,000 人
#   - 活跃率：42.5%（月活用户 / 总注册用户 200,000 人）
#   - 设备分布：APP 端占比 70%，H5 端 20%，PC 端 10%

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









SELECT COUNT(DISTINCT user_id) AS 月活跃用户数
FROM user_master
WHERE last_login_time BETWEEN DATE_SUB(CURDATE(), INTERVAL 30 DAY) AND CURDATE();