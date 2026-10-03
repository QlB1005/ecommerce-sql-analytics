-- 观测型LTV
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
#     转化率
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

# --7日留存

use ecommerce_analysis;
select *
from user_master u_m
join user_login_log u_l on u_m.user_id=u_l.user_id and date(u_m.register_time)="2026-03-10" and date(u_l.login_time) >= '2026-03-11'
    AND date(u_l.login_time) <= '2026-03-17';

SELECT count(*) FROM user_master WHERE DATE(register_time) = '2026-03-10';
SELECT count(*) FROM user_login_log WHERE DATE(login_time) = '2026-03-17';






SELECT
    u_m.user_id,
    u_m.register_time,
    u_l.login_time
FROM user_master u_m
LEFT JOIN user_login_log u_l
    ON u_m.user_id = u_l.user_id
    -- 这里改成了范围查询，防止时间格式坑人
    AND u_l.login_time >= '2026-03-17 00:00:00'
    AND u_l.login_time <= '2026-03-17 23:59:59'
WHERE u_m.register_time >= '2026-03-10 00:00:00'
  AND u_m.register_time <= '2026-03-10 23:59:59'
LIMIT 10;










