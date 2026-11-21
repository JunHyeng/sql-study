-- ============================================
-- 1~2단계 실습용 DB: "베라 카페" (MySQL 8.4)
-- DBeaver에서 이 파일을 열고 "스크립트 실행"(Alt + X)
-- 다시 실행하면 DB가 처음 상태로 초기화됩니다.
-- ============================================

DROP DATABASE IF EXISTS cafe;
CREATE DATABASE cafe DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE cafe;

-- 메뉴 테이블
CREATE TABLE menu (
    menu_id   INT          PRIMARY KEY,   -- 메뉴 번호
    name      VARCHAR(50)  NOT NULL,      -- 메뉴 이름
    category  VARCHAR(20)  NOT NULL,      -- 분류 (커피/논커피/디저트)
    price     INT          NOT NULL,      -- 가격(원)
    is_iced   TINYINT(1)   NOT NULL       -- 아이스 여부 (1=아이스, 0=핫/해당없음)
);

INSERT INTO menu VALUES
 (1,  '아메리카노',        '커피',   4000, 0),
 (2,  '아이스 아메리카노', '커피',   4500, 1),
 (3,  '카페라떼',          '커피',   4500, 0),
 (4,  '바닐라라떼',        '커피',   5000, 0),
 (5,  '콜드브루',          '커피',   5000, 1),
 (6,  '녹차라떼',          '논커피', 5000, 0),
 (7,  '자몽에이드',        '논커피', 5500, 1),
 (8,  '초코라떼',          '논커피', 5000, 0),
 (9,  '치즈케이크',        '디저트', 6000, 0),
 (10, '크로플',            '디저트', 5500, 0),
 (11, '마카롱',            '디저트', 2500, 0),
 (12, '티라미수',          '디저트', 6500, 0);

-- 고객 테이블
CREATE TABLE customers (
    customer_id INT          PRIMARY KEY,  -- 고객 번호
    name        VARCHAR(20)  NOT NULL,     -- 이름
    gender      CHAR(1),                   -- 성별 (M/F)
    birth_year  INT,                       -- 출생연도
    city        VARCHAR(20),               -- 거주 지역
    join_date   DATE,                      -- 가입일
    phone       VARCHAR(20)                -- 연락처 (없을 수도 있음 = NULL)
);

INSERT INTO customers VALUES
 (1,  '김민수', 'M', 1995, '서울', '2025-01-15', '010-1111-2222'),
 (2,  '이서연', 'F', 1999, '서울', '2025-02-03', '010-2222-3333'),
 (3,  '박지훈', 'M', 1988, '경기', '2025-02-20', NULL),
 (4,  '최유나', 'F', 2001, '서울', '2025-03-11', '010-4444-5555'),
 (5,  '정하늘', 'F', 1993, '인천', '2025-04-02', '010-5555-6666'),
 (6,  '강도윤', 'M', 1997, '경기', '2025-05-19', NULL),
 (7,  '윤채원', 'F', 2000, '서울', '2025-06-07', '010-7777-8888'),
 (8,  '임준호', 'M', 1985, '부산', '2025-07-23', '010-8888-9999'),
 (9,  '한소희', 'F', 1996, '경기', '2025-08-30', '010-9999-0000'),
 (10, '오세훈', 'M', 2002, '서울', '2025-09-14', NULL);

-- 주문 테이블 (주문 1건 = 영수증 1장)
CREATE TABLE orders (
    order_id    INT          PRIMARY KEY,
    customer_id INT,                       -- 비회원 주문이면 NULL
    order_date  DATE         NOT NULL,     -- 주문일
    payment     VARCHAR(10)  NOT NULL,     -- 결제수단 (카드/현금/페이)
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

INSERT INTO orders VALUES
 (1,  1,    '2025-10-01', '카드'),
 (2,  2,    '2025-10-01', '페이'),
 (3,  NULL, '2025-10-02', '현금'),
 (4,  4,    '2025-10-02', '카드'),
 (5,  1,    '2025-10-03', '카드'),
 (6,  5,    '2025-10-03', '페이'),
 (7,  7,    '2025-10-04', '카드'),
 (8,  3,    '2025-10-05', '현금'),
 (9,  2,    '2025-10-05', '페이'),
 (10, 8,    '2025-10-06', '카드'),
 (11, NULL, '2025-10-06', '카드'),
 (12, 9,    '2025-10-07', '페이'),
 (13, 4,    '2025-10-08', '카드'),
 (14, 6,    '2025-10-08', '현금'),
 (15, 1,    '2025-10-09', '카드'),
 (16, 7,    '2025-10-10', '페이'),
 (17, 2,    '2025-10-10', '카드'),
 (18, 5,    '2025-10-11', '카드');

-- 주문 상세 테이블 (영수증 1장에 여러 메뉴)
CREATE TABLE order_items (
    item_id   INT  PRIMARY KEY,
    order_id  INT  NOT NULL,
    menu_id   INT  NOT NULL,
    quantity  INT  NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (menu_id)  REFERENCES menu(menu_id)
);

INSERT INTO order_items VALUES
 (1,  1,  2, 1), (2,  1,  9, 1),
 (3,  2,  3, 2),
 (4,  3,  1, 1), (5,  3, 11, 3),
 (6,  4,  7, 1), (7,  4, 10, 1),
 (8,  5,  2, 1),
 (9,  6,  6, 1), (10, 6, 12, 1),
 (11, 7,  5, 2),
 (12, 8,  1, 2), (13, 8,  9, 1),
 (14, 9,  4, 1),
 (15, 10, 2, 3), (16, 10, 10, 2),
 (17, 11, 8, 1),
 (18, 12, 7, 2), (19, 12, 11, 2),
 (20, 13, 3, 1),
 (21, 14, 1, 1), (22, 14, 12, 1),
 (23, 15, 5, 1),
 (24, 16, 6, 1), (25, 16, 9, 2),
 (26, 17, 2, 2),
 (27, 18, 4, 1), (28, 18, 11, 1);

-- 확인용: 아래 4줄 결과가 12, 10, 18, 28 이면 성공
SELECT COUNT(*) AS menu_cnt        FROM menu;
SELECT COUNT(*) AS customer_cnt    FROM customers;
SELECT COUNT(*) AS order_cnt       FROM orders;
SELECT COUNT(*) AS order_item_cnt  FROM order_items;
