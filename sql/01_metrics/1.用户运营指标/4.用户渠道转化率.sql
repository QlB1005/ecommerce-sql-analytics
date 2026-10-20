-- 4.用户渠道转化率
-- 指标说明：某注册渠道的新增用户中，完成首单支付的用户比例
-- 说明：保留原始查询口径与计算逻辑；各查询可按需单独执行。

use ecommerce_analysis;
show tables;

with new_user_pay as
    (select u_m.channel_source as 渠道,
           count(distinct u_m.user_id) as 新增用户首单支付用户数
    from user_master u_m
    join order_master o_m on u_m.user_id = o_m.user_id and
                             date(u_m.register_time)<='2026-03-17' and date(u_m.register_time)>= date_add('2026-03-17',interval -90 day) and
                              payment_status="Paid" and o_m.order_time >= u_m.register_time
    group by u_m.channel_source),
new_user as(
    select u_m.channel_source as 渠道,
    count(distinct u_m.user_id) as 新增用户总数
    from user_master u_m
    where      date(u_m.register_time)<='2026-03-17' and date(u_m.register_time)>= date_add('2026-03-17',interval -90 day)
    group by u_m.channel_source
),
brand as(
    select "品牌A" as 品牌 union all
                       select "品牌B" as 品牌 union all
                                          select "品牌C" as 品牌 union all
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
;

with channel_new_users as (select
        channel_source,count(distinct user_id) as new_user_count
    from user_master
    where register_time between date_sub(curdate(), interval 30 day) and curdate()
    group by channel_source
),
channel_paid_users as (select
        u.channel_source,count(distinct u.user_id) as paid_user_count
    from user_master u
    join order_master o on u.user_id = o.user_id
    where
        u.register_time between date_sub(curdate(), interval 30 day) and curdate()
        and o.payment_status = 'PAID'and o.order_time >= u.register_time
    group by u.channel_source
)select
    c.channel_source,
    c.new_user_count,
    p.paid_user_count,round(p.paid_user_count / c.new_user_count * 100, 2) as conversion_rate
from channel_new_users c
left join channel_paid_users p on c.channel_source = p.channel_source;
