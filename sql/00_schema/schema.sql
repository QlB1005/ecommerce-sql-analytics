CREATE DATABASE IF NOT EXISTS ecommerce_analysis
  DEFAULT CHARSET utf8mb4;
USE ecommerce_analysis;

CREATE TABLE IF NOT EXISTS user_master
(
    user_id         VARCHAR(32) PRIMARY KEY COMMENT '用户唯一标识',
    username        VARCHAR(50) UNIQUE NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    email           VARCHAR(100) UNIQUE,
    phone           VARCHAR(20) UNIQUE,
    gender          ENUM('M', 'F', 'U') DEFAULT 'U',
    birthdate       DATE,
    register_time   DATETIME NOT NULL,
    last_login_time DATETIME,
    device_type     ENUM('PC', 'APP', 'H5') DEFAULT 'APP',
    channel_source  VARCHAR(50),
    city            VARCHAR(50),
    user_status     TINYINT DEFAULT 1,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

CREATE TABLE IF NOT EXISTS user_login_log
(
    log_id      BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id     VARCHAR(32) NOT NULL,
    login_time  DATETIME NOT NULL,
    login_date  DATE GENERATED ALWAYS AS (DATE(login_time)) VIRTUAL,
    device_type ENUM('PC', 'APP', 'H5') DEFAULT 'APP',
    ip_address  VARCHAR(45),
    city        VARCHAR(50),
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_time (user_id, login_time),
    INDEX idx_login_date (login_date),
    FOREIGN KEY (user_id) REFERENCES user_master(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户登录流水表';

CREATE TABLE IF NOT EXISTS product_category
(
    category_id        VARCHAR(32) PRIMARY KEY,
    parent_category_id VARCHAR(32),
    category_name      VARCHAR(50) NOT NULL,
    category_level     TINYINT NOT NULL,
    sort_order         INT DEFAULT 0,
    is_enable          TINYINT DEFAULT 1,
    created_at         DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_parent_category (parent_category_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='商品分类表';

CREATE TABLE IF NOT EXISTS product_detail
(
    product_id       VARCHAR(32) PRIMARY KEY,
    category_id      VARCHAR(32) NOT NULL,
    product_name     VARCHAR(200) NOT NULL,
    brand            VARCHAR(50),
    sku_code         VARCHAR(50) UNIQUE,
    specifications   VARCHAR(200),
    price            DECIMAL(10, 2) NOT NULL,
    cost_price       DECIMAL(10, 2) NOT NULL,
    stock_quantity   INT DEFAULT 0,
    locked_quantity  INT DEFAULT 0,
    sales_count      INT DEFAULT 0,
    shelf_time       DATETIME,
    shelf_status     TINYINT DEFAULT 1,
    create_time      DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_category (category_id),
    FOREIGN KEY (category_id) REFERENCES product_category(category_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='商品表';

CREATE TABLE IF NOT EXISTS order_master
(
    order_id         VARCHAR(32) PRIMARY KEY,
    user_id          VARCHAR(32) NOT NULL,
    order_time       DATETIME NOT NULL,
    total_amount     DECIMAL(10, 2) NOT NULL,
    discount_amount  DECIMAL(10, 2) DEFAULT 0,
    payment_amount   DECIMAL(10, 2) NOT NULL,
    payment_status   ENUM('UNPAID', 'PAID', 'REFUNDED') DEFAULT 'UNPAID',
    shipping_status  ENUM('PENDING', 'SHIPPED', 'DELIVERED') DEFAULT 'PENDING',
    city             VARCHAR(50),
    payment_time     DATETIME,
    delivery_time    DATETIME,
    receive_time     DATETIME,
    INDEX idx_user (user_id),
    FOREIGN KEY (user_id) REFERENCES user_master(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单表';

CREATE TABLE IF NOT EXISTS order_detail
(
    detail_id          VARCHAR(32) PRIMARY KEY,
    order_id           VARCHAR(32) NOT NULL,
    product_id         VARCHAR(32) NOT NULL,
    purchase_quantity  INT NOT NULL,
    unit_price         DECIMAL(10, 2) NOT NULL,
    subtotal_amount    DECIMAL(10, 2) NOT NULL,
    is_return          TINYINT DEFAULT 0,
    return_quantity    INT DEFAULT 0,
    INDEX idx_order (order_id),
    INDEX idx_product (product_id),
    FOREIGN KEY (order_id) REFERENCES order_master(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES product_detail(product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单明细表';

CREATE TABLE IF NOT EXISTS payment_record
(
    payment_id      VARCHAR(32) PRIMARY KEY,
    order_id        VARCHAR(32) NOT NULL,
    payment_method  ENUM('ALIPAY', 'WECHAT', 'CARD') NOT NULL,
    payment_amount  DECIMAL(10, 2) NOT NULL,
    transaction_id  VARCHAR(100),
    payment_time    DATETIME NOT NULL,
    payment_status  ENUM('SUCCESS', 'FAILED') NOT NULL,
    INDEX idx_order (order_id),
    FOREIGN KEY (order_id) REFERENCES order_master(order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='支付表';

CREATE TABLE IF NOT EXISTS traffic_log
(
    log_id            BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id           VARCHAR(32),
    session_id        VARCHAR(50),
    page_url          VARCHAR(255) NOT NULL,
    referer_url       VARCHAR(255),
    view_time         DATETIME NOT NULL,
    duration_seconds  INT,
    device_type       ENUM('PC', 'APP', 'H5') DEFAULT 'APP',
    ip_address        VARCHAR(45),
    city              VARCHAR(50),
    created_at        DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_time (user_id, view_time),
    INDEX idx_session (session_id),
    FOREIGN KEY (user_id) REFERENCES user_master(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='流量日志表';

CREATE TABLE IF NOT EXISTS user_behavior_event
(
    event_id     BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id      VARCHAR(32) NOT NULL,
    session_id   VARCHAR(50),
    event_type   ENUM('PAGE_VIEW','PRODUCT_CLICK','ADD_TO_CART','REMOVE_FROM_CART','FAVORITE','SHARE','SEARCH','COUPON_GET','CREATE_ORDER','PAYMENT_SUCCESS') NOT NULL,
    product_id   VARCHAR(32),
    quantity     INT DEFAULT 1,
    event_time   DATETIME NOT NULL,
    page_url     VARCHAR(255),
    device_type  ENUM('PC', 'APP', 'H5') DEFAULT 'APP',
    city         VARCHAR(50),
    extra_info   JSON,
    created_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_time (user_id, event_time),
    INDEX idx_event_type (event_type),
    FOREIGN KEY (user_id) REFERENCES user_master(user_id),
    FOREIGN KEY (product_id) REFERENCES product_detail(product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户行为事件表';

CREATE TABLE IF NOT EXISTS shopping_cart
(
    cart_id      BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id      VARCHAR(32) NOT NULL,
    product_id   VARCHAR(32) NOT NULL,
    quantity     INT NOT NULL DEFAULT 1,
    add_time     DATETIME NOT NULL,
    update_time  DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_valid     TINYINT DEFAULT 1,
    order_id     VARCHAR(32),
    INDEX idx_user (user_id),
    UNIQUE KEY uk_user_product (user_id, product_id),
    FOREIGN KEY (user_id) REFERENCES user_master(user_id),
    FOREIGN KEY (product_id) REFERENCES product_detail(product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='购物车表';