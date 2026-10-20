-- Database schema aligned with the confirmed original project structure.
-- DDL only; no original business data is included.
create database if not exists ecommerce_analysis default charset utf8mb4;
use ecommerce_analysis;

create table user_master (
        user_id varchar(32) primary key, username varchar(50) unique not null,
        password_hash varchar(255) not null, email varchar(100) unique, phone varchar(20) unique,
        gender enum('M','F','U') default 'U', birthdate date, register_time datetime not null,
        last_login_time datetime, device_type enum('PC','APP','H5') default 'APP',
        channel_source varchar(50), city varchar(50), user_status tinyint default 1,
        index idx_channel_reg (channel_source, register_time)
    ) engine=innodb default charset=utf8mb4;

create table user_login_log (
        log_id bigint auto_increment primary key, user_id varchar(32) not null,
        login_time datetime not null, device_type enum('PC','APP','H5') default 'APP',
        ip_address varchar(45), city varchar(50),
        index idx_user_time (user_id, login_time),
        foreign key (user_id) references user_master(user_id)
    ) engine=innodb default charset=utf8mb4;

create table product_category (
        category_id varchar(32) primary key, parent_category_id varchar(32),
        category_name varchar(50) not null, category_level tinyint not null,
        sort_order int default 0, is_enable tinyint default 1
    ) engine=innodb default charset=utf8mb4;

create table product_detail (
        product_id varchar(32) primary key, category_id varchar(32) not null,
        product_name varchar(200) not null, brand varchar(50),
        season_type enum('winter','spring','summer','autumn') not null,
        sku_code varchar(50) unique, specifications varchar(200),
        price decimal(10,2) not null, cost_price decimal(10,2) not null,
        stock_quantity int default 0, locked_quantity int default 0, sales_count int default 0,
        shelf_time datetime, shelf_status tinyint default 1,
        foreign key (category_id) references product_category(category_id)
    ) engine=innodb default charset=utf8mb4;

create table order_master (
        order_id varchar(32) primary key, user_id varchar(32) not null, order_time datetime not null,
        total_amount decimal(10,2) not null, discount_amount decimal(10,2) default 0,
        payment_amount decimal(10,2) not null, commission_amount decimal(10,2) default 0,
        shipping_fee decimal(10,2) default 0, shipping_cost decimal(10,2) default 0,
        refund_amount decimal(10,2) default 0,
        payment_status enum('UNPAID','PAID','REFUNDED') default 'UNPAID',
        shipping_status enum('PENDING','SHIPPED','DELIVERED') default 'PENDING',
        city varchar(50), payment_time datetime, delivery_time datetime, receive_time datetime,
        index idx_user (user_id), index idx_order_time (order_time),
        foreign key (user_id) references user_master(user_id)
    ) engine=innodb default charset=utf8mb4;

create table order_detail (
        detail_id varchar(32) primary key, order_id varchar(32) not null, product_id varchar(32) not null,
        purchase_quantity int not null, unit_price decimal(10,2) not null, subtotal_amount decimal(10,2) not null,
        is_return tinyint default 0, return_quantity int default 0,
        foreign key (order_id) references order_master(order_id) on delete cascade,
        foreign key (product_id) references product_detail(product_id)
    ) engine=innodb default charset=utf8mb4;

create table payment_record (
        payment_id varchar(32) primary key, order_id varchar(32) not null,
        payment_method enum('ALIPAY','WECHAT','CARD') not null, payment_amount decimal(10,2) not null,
        transaction_id varchar(100), payment_time datetime not null,
        payment_status enum('SUCCESS','FAILED') not null,
        foreign key (order_id) references order_master(order_id)
    ) engine=innodb default charset=utf8mb4;

create table traffic_log (
        log_id bigint auto_increment primary key, user_id varchar(32), session_id varchar(50),
        page_url varchar(255) not null, referer_url varchar(255), view_time datetime not null,
        duration_seconds int, device_type enum('PC','APP','H5') default 'APP',
        ip_address varchar(45), city varchar(50),
        index idx_user_time (user_id, view_time),
        foreign key (user_id) references user_master(user_id)
    ) engine=innodb default charset=utf8mb4;

create table user_behavior_event (
        event_id bigint auto_increment primary key, user_id varchar(32) not null, session_id varchar(50),
        event_type enum('PAGE_VIEW','PRODUCT_CLICK','ADD_TO_CART','REMOVE_FROM_CART',
            'FAVORITE','SHARE','SEARCH','COUPON_GET','CREATE_ORDER','PAYMENT_SUCCESS') not null,
        product_id varchar(32), quantity int default 1, event_time datetime not null,
        page_url varchar(255), device_type enum('PC','APP','H5') default 'APP', city varchar(50), extra_info json,
        index idx_user_time (user_id, event_time),
        foreign key (user_id) references user_master(user_id),
        foreign key (product_id) references product_detail(product_id)
    ) engine=innodb default charset=utf8mb4;

create table shopping_cart (
        cart_id bigint auto_increment primary key, user_id varchar(32) not null, product_id varchar(32) not null,
        quantity int not null default 1, add_time datetime not null, is_valid tinyint default 1, order_id varchar(32),
        unique key uk_user_product (user_id, product_id),
        foreign key (user_id) references user_master(user_id),
        foreign key (product_id) references product_detail(product_id)
    ) engine=innodb default charset=utf8mb4;

create table ad_spend_daily (
        stat_date date not null, channel_source varchar(50) not null,
        spend_amount decimal(12,2) not null, impression int default 0, click int default 0,
        primary key (stat_date, channel_source)
    ) engine=innodb default charset=utf8mb4 comment='渠道每日广告投放费用及效果统计表';
