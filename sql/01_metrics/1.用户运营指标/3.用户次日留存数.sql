# - 定义：统计当日新增用户中，在次日（注册日 + 1 天）再次登录的用户比例，反映新用户对产品的初期接受度。
# - 核心作用：评估新用户体验（如注册流程、首屏引导、核心功能），是产品优化的关键指标（留存率低意味着用户流失风险高）。
# - 计算逻辑：
# 公式：次日留存率 = （次日登录的新增用户数 / 当日新增用户数）× 100%
# 涉及字段：user_id、register_time（用于筛选当日新增）、last_login_time（用于判断次日登录）。
# - 结果字段示例：
#   - 统计日期：2025-06-15
#   - 当日新增用户数：1,000 人
#   - 次日登录用户数：280 人
#   - 次日留存率：28%
# - 理想结果：
#   - 整体留存率≥20%（电商行业均值），且高价值渠道（如抖音）的新用户留存率≥25%。
#   - 留存率随用户分层提升：付费用户次日留存≥35%，未付费用户≥15%。
# - 业务解读：
#   - 若留存率＜15%，需优化新用户引导（如简化首单流程、赠送新人券），或排查产品是否存在 “注册后无明确操作路径” 的问题（如首页杂乱无重点）。
use ecommerce_analysis;
show tables;
#统计每日次日留存率
DROP TABLE IF EXISTS retention_rate_90_day;

create table retention_rate_90_day as
    select
        date(u_m.register_time) as 统计日期,
        count(distinct u_m.user_id) as 当日新增用户数,
        COUNT(DISTINCT u_l.user_id) AS 次日登录用户数,
        case
            when count(distinct u_m.user_id)=0 then 0
            else round(COUNT(DISTINCT u_l.user_id) /
                       count(distinct u_m.user_id),4)
            end 次日留存率
        from user_master u_m
        left join user_login_log u_l on u_m.user_id=u_l.user_id and date(u_l.login_date)=date_add(date(u_m.register_time),interval 1 day)
        where date(u_m.register_time) between date_add("2026-03-17",interval -90 day) and "2026-03-17"
        group by date(u_m.register_time)
        order by 统计日期 asc;

select * from retention_rate_90_day;

create table retention_rate_90_day_week as
SELECT
    DATE_SUB(DATE(u_m.register_time), INTERVAL WEEKDAY(DATE(u_m.register_time)) DAY) AS 统计周起始日,
    COUNT(DISTINCT u_m.user_id) AS 当周新增用户数,
    COUNT(DISTINCT u_l.user_id) AS 当周新增用户的次日登录数,
    CASE
        WHEN COUNT(DISTINCT u_m.user_id) = 0 THEN 0
        ELSE ROUND(COUNT(DISTINCT u_l.user_id) / COUNT(DISTINCT u_m.user_id), 4)
    END AS 当周次日留存率
FROM user_master u_m
LEFT JOIN user_login_log u_l
    ON u_m.user_id = u_l.user_id
    AND DATE(u_l.login_date) = DATE_ADD(DATE(u_m.register_time), INTERVAL 1 DAY)
WHERE
    DATE(u_m.register_time) BETWEEN DATE_ADD('2026-03-17', INTERVAL -90 DAY) AND '2026-03-17'
GROUP BY DATE_SUB(DATE(u_m.register_time), INTERVAL WEEKDAY(DATE(u_m.register_time)) DAY)
ORDER BY 统计周起始日 ASC;
select * from retention_rate_90_day_week;


# create table retention_rate_90_day as

# 总环比 （now-last）/last
# 留存率=次日登录人数 / 总人数
drop table if exists change_pop_90;
create table  change_pop_90
with current_90_day as
    (select
        round(COUNT(DISTINCT u_l.user_id)/count(distinct u_m.user_id),4) as now_90
        from user_master u_m
        left join user_login_log u_l on u_m.user_id=u_l.user_id and date(u_l.login_date)=date_add(date(u_m.register_time),interval 1 day)
        where date(u_m.register_time) >= date_add("2026-03-17", interval -90 day) and date(register_time) < "2026-03-17"),
last_90_day as (
    select
        round(COUNT(DISTINCT u_l.user_id)/count(distinct u_m.user_id),4)    last_90
        from user_master u_m
        left join user_login_log u_l on u_m.user_id=u_l.user_id and date(u_l.login_date)=date_add(date(u_m.register_time),interval 1 day)
        where date(register_time)>date_add("2025-12-18",interval  -90 day) and date(register_time)<"2025-12-18"
)
select concat(round((now_90-last_90) / last_90*100,2 ),"%")as 环比
     from current_90_day,last_90_day
;


# 渠道对比 留存率=次日登录人数 / 总人数
drop table if exists channel_90_day;
create table channel_90_day as
select u_m.channel_source,
       count(distinct u_m.user_id) 渠道新增人数,
       case
            when count(distinct u_m.user_id)=0 then 0
            else round(COUNT(DISTINCT u_l.user_id) /
                       count(distinct u_m.user_id),4)
            end    渠道留存率
        from user_master u_m
        left join user_login_log u_l on u_m.user_id=u_l.user_id and date(u_l.login_date)=date_add(date(u_m.register_time),interval 1 day)
 where date(u_m.register_time) >= date_add("2026-03-17", interval -90 day) and date(u_m.register_time) < "2026-03-17"
group by u_m.channel_source;


select *
from user_master u_m
left join user_login_log u_l on u_m.user_id=u_l.user_id and date(u_l.login_date)=date_add(date(u_m.register_time),interval 1 day);


# LTV=平均客单价 (AOV)×(年均复购次数或人均购买频次)×平均留存年数（预测型）

# 平均客单价（avg 标准客单价
with Average_per_customer as (
    select round(sum(payment_amount)/count(order_id),2) 客单价
from order_master
where date(payment_time)<='2026-03-17' and date(payment_time)>= date_add('2026-03-17',interval -90 day)
  and payment_status="Paid"
),
Annual_repurchase as (
    select round(count(order_id)/count(distinct user_id),2) 人均购买频次
    from order_master
    where date(payment_time)<='2026-03-17' and date(payment_time)>= date_add('2026-03-17',interval -1 year )
  and payment_status="Paid"
),
# 平均留存年限
Average_retention_years as (
    with temp as
    (select min(date(payment_time)) as first_order_time,
           max(date(payment_time)) as last_order_time
    from order_master
    where payment_status="Paid"  and  user_id IN (
        SELECT user_id
        FROM order_master
        WHERE payment_time < DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
    )
    group by user_id
    HAVING COUNT(order_id) > 1)
    select  round(AVG(DATEDIFF(last_order_time, first_order_time)) / 365.0 * 1.4,2) AS 平均留存年数,
            COUNT(*) AS user_count_used
    from temp
)
select round(客单价*人均购买频次*平均留存年数,2) as LTV
from Average_per_customer,Annual_repurchase,Average_retention_years
;

select * from product_detail;


# 客单价

select u_m.channel_source 渠道,p_d.brand 品牌,
        round(sum(o_m.payment_amount)/count(o_d.order_id),2) 客单价
from order_master o_m
join order_detail o_d on o_m.order_id=o_d.order_id and
                         date(o_m.payment_time)<='2026-03-17' and date(o_m.payment_time)>= date_add('2026-03-17',interval -90 day) and
                          payment_status="Paid"
join product_detail p_d on o_d.product_id=p_d.product_id
join user_master u_m on o_m.user_id=u_m.user_id         AND DATE(u_m.register_time) <= '2026-03-17'
        AND DATE(u_m.register_time) >= DATE_ADD('2026-03-17', INTERVAL -90 DAY)
group by u_m.channel_source,p_d.brand
order by channel_source;

# 公式：毛利率 = [（售价 - 成本价）/ 售价] × 100%（可按商品、分类、品牌聚合计算） (应该用是实付）
with temp as(
    SELECT p_d.brand,u_m.channel_source,
price*(payment_amount/total_amount)*o_d.purchase_quantity as 单价真实销售,
p_d.cost_price*o_d.purchase_quantity as 单价成本价
FROM  order_detail o_d
join product_detail p_d on o_d.product_id=p_d.product_id
join order_master o_m on o_d.order_id=o_m.order_id
join user_master u_m on o_m.user_id=u_m.user_id
where o_d.order_id=o_m.order_id and
                         date(o_m.payment_time)<='2026-03-17' and date(o_m.payment_time)>= date_add('2026-03-17',interval -90 day) and
                          payment_status="PAID"
    )
select temp.channel_source 渠道,temp.brand 品牌,
    (sum(temp.单价真实销售)-sum(temp.单价成本价))/sum(temp.单价真实销售) as 毛利率
from temp
group by temp.channel_source,temp.brand
order by 渠道;
;

# 人均购买频次
   select   u_m.channel_source,p_d.brand,
            round(count(o_m.order_id)/count(distinct o_m.user_id),2) 人均购买频次
    from order_master o_m
    join user_master u_m on o_m.user_id=u_m.user_id and
                            date(payment_time)<='2026-03-17' and date(payment_time)>= date_add('2026-03-17',interval -90 day )
  and payment_status="Paid"         AND DATE(u_m.register_time) <= '2026-03-17'
        AND DATE(u_m.register_time) >= DATE_ADD('2026-03-17', INTERVAL -90 DAY)
    join order_detail o_d on o_m.order_id=o_d.order_id
    join product_detail p_d on o_d.product_id=p_d.product_id
   group by u_m.channel_source,p_d.brand
   order by u_m.channel_source;


# 公式：渠道转化率 = （渠道新增用户中首单支付的用户数 / 渠道新增用户总数）× 100%
with new_user_pay as
    (select u_m.channel_source as 渠道,
           count(distinct u_m.user_id) as 新增用户首单支付用户数
    from user_master u_m
    join order_master o_m on u_m.user_id = o_m.user_id and
                             date(u_m.register_time)<='2026-03-17' and date(u_m.register_time)>= date_add('2026-03-17',interval -90 day) and
                              payment_status="Paid" and o_m.order_time >= u_m.register_time
    group by u_m.channel_source),
new_user as(
    select channel_source as 渠道,
    count(distinct user_id) as 新增用户总数
    from user_master
    where date(register_time)<='2026-03-17' and date(register_time) >= date_add('2026-03-17',interval -90 day)
    group by channel_source
)
select  n_u.渠道,
       新增用户总数,
       新增用户首单支付用户数,
       round(新增用户首单支付用户数/新增用户总数,2) as 渠道转化率
from new_user n_u
join new_user_pay n_p on n_u.渠道=n_p.渠道 ;



with ke_avg as (
    select u_m.channel_source 渠道,p_d.brand 品牌,
        round(sum(o_m.payment_amount)/count(o_d.order_id),2) 客单价
    from order_master o_m
    join order_detail o_d on o_m.order_id=o_d.order_id and
                             date(o_m.payment_time)<='2026-03-17' and date(o_m.payment_time)>= date_add('2026-03-17',interval -90 day) and
                              payment_status="Paid"
    join product_detail p_d on o_d.product_id=p_d.product_id
    join user_master u_m on o_m.user_id=u_m.user_id         AND DATE(u_m.register_time) <= '2026-03-17'
        AND DATE(u_m.register_time) >= DATE_ADD('2026-03-17', INTERVAL -90 DAY)
    group by u_m.channel_source,p_d.brand
    order by channel_source
),
maoli as(
        with temp as(
        SELECT p_d.brand,u_m.channel_source,
    price*(payment_amount/total_amount)*o_d.purchase_quantity as 单价真实销售,
    p_d.cost_price*o_d.purchase_quantity as 单价成本价
    FROM  order_detail o_d
    join product_detail p_d on o_d.product_id=p_d.product_id
    join order_master o_m on o_d.order_id=o_m.order_id
    join user_master u_m on o_m.user_id=u_m.user_id
    where o_d.order_id=o_m.order_id and
                             date(o_m.payment_time)<='2026-03-17' and date(o_m.payment_time)>= date_add('2026-03-17',interval -90 day) and
                              payment_status="PAID"
        )
    select temp.channel_source 渠道,temp.brand 品牌,
        (sum(temp.单价真实销售)-sum(temp.单价成本价))/sum(temp.单价真实销售) as 毛利率
    from temp
    group by temp.channel_source,temp.brand
    order by 渠道
),
people_purchase as (
       select   u_m.channel_source 渠道,p_d.brand 品牌,
            round(count(o_m.order_id)/count(distinct o_m.user_id),2) 人均购买频次
    from order_master o_m
    join user_master u_m on o_m.user_id=u_m.user_id and
                            date(payment_time)<='2026-03-17' and date(payment_time)>= date_add('2026-03-17',interval -90 day )
  and payment_status="Paid"         AND DATE(u_m.register_time) <= '2026-03-17'
        AND DATE(u_m.register_time) >= DATE_ADD('2026-03-17', INTERVAL -90 DAY)
    join order_detail o_d on o_m.order_id=o_d.order_id
    join product_detail p_d on o_d.product_id=p_d.product_id
   group by u_m.channel_source,p_d.brand
   order by u_m.channel_source
),
tran as (
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
    select "品牌 A" as 品牌 union all
                       select "品牌 B" as 品牌 union all
                                          select "品牌 C" as 品牌 union all
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
)
select ke_avg.渠道,ke_avg.品牌,
       round(ke_avg.客单价*maoli.毛利率*people_purchase.人均购买频次*tran.渠道转化率,2) as LTV
from ke_avg
join maoli on ke_avg.渠道 = maoli.渠道 and ke_avg.品牌 = maoli.品牌
join people_purchase on ke_avg.渠道 = people_purchase.渠道 and ke_avg.品牌 = people_purchase.品牌
join tran on ke_avg.渠道 = tran.渠道 and ke_avg.品牌 = tran.品牌
order by LTV desc;








