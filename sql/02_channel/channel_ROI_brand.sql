-- 02_channel_roi.sql
-- 渠道归因：订单跟 user_master.channel_source（注册渠道）
-- 成交：payment_status = 'paid'，时间用 order_time
-- 窗口：2025-12-17 ~ 2026-03-17
-- gmv / 佣金 / 运费 / 部分退：只打订单头，不要 join 明细后再 sum
-- 货本：明细 is_return = 0
-- 微信花费是社群工具费，roi 再高也不等于该加信息流
-- 抖音 / 京东单量很小，只当试投失败

-- 渠道贡献 roi
with t_order as (
    select u_m.channel_source,
           sum(o_m.payment_amount) as gmv,
           sum(o_m.commission_amount) as 佣金,
           sum(o_m.shipping_fee) as 用户运费,
           sum(o_m.shipping_cost) as 商家运费,
           sum(o_m.refund_amount) as 退款,
           count(distinct o_m.order_id) as 单数
    from order_master o_m
    join user_master u_m on o_m.user_id = u_m.user_id
    where o_m.payment_status = 'paid'
      and o_m.order_time >= '2025-12-17 00:00:00'
      and o_m.order_time <= '2026-03-17 23:59:59'
    group by u_m.channel_source
),
t_cogs as (
    select u_m.channel_source,
           round(sum(o_d.purchase_quantity * p_d.cost_price), 2) as 货本
    from order_master o_m
    join user_master u_m on o_m.user_id = u_m.user_id
    join order_detail o_d on o_m.order_id = o_d.order_id
    join product_detail p_d on o_d.product_id = p_d.product_id
    where o_m.payment_status = 'paid'
      and o_m.order_time >= '2025-12-17 00:00:00'
      and o_m.order_time <= '2026-03-17 23:59:59'
      and o_d.is_return = 0
    group by u_m.channel_source
),
t_spend as (
    select channel_source,
           sum(spend_amount) as 渠道花费
    from ad_spend_daily
    where stat_date >= '2025-12-17'
      and stat_date <= '2026-03-17'
    group by channel_source
)
select t_order.channel_source,
       t_order.单数,
       round(t_order.gmv, 2) as gmv,
       t_cogs.货本,
       round(t_order.gmv - t_cogs.货本, 2) as 货毛,
       round((t_order.gmv - t_cogs.货本) / t_order.gmv, 4) as 货毛利率,
       round(t_order.佣金, 2) as 佣金,
       round(t_order.用户运费, 2) as 用户运费,
       round(t_order.商家运费, 2) as 商家运费,
       round(t_order.退款, 2) as 退款,
       round(t_spend.渠道花费, 2) as 渠道花费,
       round(t_order.gmv / t_spend.渠道花费, 4) as roas,
       round(t_spend.渠道花费 / t_order.gmv, 4) as 费比,
       round(t_order.gmv + t_order.用户运费 - t_cogs.货本 - t_order.佣金
             - t_spend.渠道花费 - t_order.商家运费 - t_order.退款, 4) as 贡献,
       round((t_order.gmv + t_order.用户运费 - t_cogs.货本 - t_order.佣金
             - t_spend.渠道花费 - t_order.商家运费 - t_order.退款)
             / t_spend.渠道花费, 4) as 贡献roi
from t_order
join t_cogs on t_order.channel_source = t_cogs.channel_source
join t_spend on t_order.channel_source = t_spend.channel_source
order by 贡献 desc;


-- 02_assortment.sql
-- 渠道 × 品牌货盘：定主推，不加广告预算
-- 订单头金额按 行小计 / 整单合计 分摊，避免 join 明细后 gmv 加倍
-- 单量 < 30 或抖音 / 京东不参与主推排名

with temp as (
    select u_m.channel_source,
           p_d.brand,
           round(sum(o_m.payment_amount * (o_d.subtotal_amount / o_m.total_amount)), 2) as gmv,
           sum(o_d.purchase_quantity) as 件数,
           count(distinct o_d.order_id) as 单量,
           sum(case when o_d.is_return = 0 then o_d.purchase_quantity * p_d.cost_price else 0 end) as 货本,
           sum(case when o_d.is_return = 1 then 1 else 0 end) / count(*) as 退货率,
           sum(o_m.commission_amount * (o_d.subtotal_amount / o_m.total_amount)) as 佣金,
           sum(o_m.shipping_fee * (o_d.subtotal_amount / o_m.total_amount)) as 用户运费,
           sum(o_m.shipping_cost * (o_d.subtotal_amount / o_m.total_amount)) as 商家运费,
           sum(o_m.refund_amount * (o_d.subtotal_amount / o_m.total_amount)) as 退款
    from order_master o_m
    join user_master u_m on o_m.user_id = u_m.user_id
    join order_detail o_d on o_m.order_id = o_d.order_id
    join product_detail p_d on o_d.product_id = p_d.product_id
    where o_m.payment_status = 'paid'
      and o_m.order_time >= '2025-12-17 00:00:00'
      and o_m.order_time <= '2026-03-17 23:59:59'
      and o_m.total_amount > 0
    group by u_m.channel_source, p_d.brand
)
select channel_source as 渠道,
       brand as 品牌,
       单量,
       件数,
       gmv,
       货本,
       gmv - 货本 as 货毛,
       round((gmv - 货本) / gmv, 4) as 货毛利率,
       round(gmv + 用户运费 - 货本 - 佣金 - 商家运费 - 退款, 4) as 毛利贡献,
       退货率
from temp
where 单量 > 30
order by 渠道, 单量 desc;