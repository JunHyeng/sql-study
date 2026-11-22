---
title: 7강 GROUP BY와 HAVING
date: 2026-11-22
tags: [sql, 1단계, group-by, having]
---

# 7강: GROUP BY와 HAVING

## 0. 복습: 행 단위 함수 vs 집계 함수

6강 확인 질문 3번을 다시 짚고 시작합니다. 아래 쿼리들의 **결과 행 수**를 먼저 예상해 보고, 실행해서 맞는지 확인하세요.

```sql
SELECT ROUND(price / 1.1) FROM menu;                         -- ① ?행
SELECT SUM(price) FROM menu;                                  -- ② ?행
SELECT ROUND(price / 1.1) FROM menu WHERE category = '디저트'; -- ③ ?행
SELECT SUM(price) FROM menu WHERE category = '디저트';        -- ④ ?행
```

| 함수 종류 | 예시 | N행이 들어가면 |
|---|---|---|
| 행 단위 함수 | `ROUND`, `LEFT`, `YEAR`, `CASE` | N행 |
| 집계 함수 | `SUM`, `COUNT`, `AVG`, `MAX`, `MIN` | **1행** |

> 정답은 맨 아래 실습 문제 "복습"의 답안 칸에 적어 주세요.

## 오늘의 목표

- `GROUP BY`로 **그룹마다** 집계할 수 있다. (분류별 메뉴 수, 지역별 고객 수)
- `HAVING`으로 **집계 결과에 조건**을 걸 수 있다. (2번 이상 주문한 고객)
- `WHERE`와 `HAVING`의 차이를 설명할 수 있다.

## 1. GROUP BY: 묶어서 집계

6강의 `COUNT(*)`는 테이블 전체를 1행으로 줄였습니다. `GROUP BY`를 쓰면 **그룹마다 1행씩** 나옵니다.

```sql
SELECT category, COUNT(*) AS 메뉴수
FROM menu
GROUP BY category;
```

| category | 메뉴수 |
|---|---|
| 논커피 | 3 |
| 디저트 | 4 |
| 커피 | 5 |

DB가 하는 일:

1. `category` 값이 같은 행끼리 **바구니**에 나눠 담는다. (커피 바구니 5개, 논커피 바구니 3개, 디저트 바구니 4개)
2. 바구니마다 `COUNT(*)`를 계산한다.
3. 바구니 하나당 결과 **1행**.

> [!TIP]
> 엑셀의 **피벗 테이블**과 같습니다. "행" 영역에 넣는 것이 `GROUP BY` 컬럼, "값" 영역에 넣는 것이 집계 함수입니다.

### 규칙: SELECT에는 "그룹 기준"과 "집계 함수"만

```sql
-- ✅ category는 GROUP BY 기준이라 OK
SELECT category, COUNT(*) FROM menu GROUP BY category;

-- ❌ name은 바구니 안에 여러 개라 무엇을 보여 줄지 모름 → 6강 10번과 같은 오류
SELECT category, name, COUNT(*) FROM menu GROUP BY category;
```

### 여러 집계를 한 번에

```sql
SELECT category,
       COUNT(*)          AS 메뉴수,
       ROUND(AVG(price)) AS 평균가격,
       MAX(price)        AS 최고가
FROM menu
GROUP BY category
ORDER BY 평균가격 DESC;
```

### 여러 컬럼으로 묶기

```sql
SELECT category, is_iced, COUNT(*) AS 메뉴수
FROM menu
GROUP BY category, is_iced;
```

category와 is_iced의 **조합**마다 1행이 나옵니다. (커피+아이스, 커피+핫, …)

### 5강 함수로 만든 값으로 묶기

```sql
SELECT MONTH(join_date) AS 가입월,
       COUNT(*)         AS 가입자수
FROM customers
GROUP BY MONTH(join_date)
ORDER BY 가입월;
```

"월별 가입자 수", "가격대별 메뉴 수"처럼 **계산한 값으로도 묶을 수 있습니다.** 실무 분석에서 가장 많이 쓰는 형태입니다.

## 2. NULL도 하나의 그룹이 된다

```sql
SELECT customer_id, COUNT(*) AS 주문수
FROM orders
GROUP BY customer_id;
```

결과에 `customer_id`가 `NULL`인 행(비회원 주문 2건)이 **한 그룹**으로 나옵니다. 회원만 보고 싶으면 먼저 `WHERE customer_id IS NOT NULL`로 걸러 냅니다.

## 3. HAVING: 그룹에 조건 걸기

"2번 이상 주문한 고객"처럼 **집계 결과**로 거르려면 `HAVING`을 씁니다.

```sql
SELECT customer_id, COUNT(*) AS 주문수
FROM orders
WHERE customer_id IS NOT NULL      -- ① 행을 먼저 거름 (비회원 제외)
GROUP BY customer_id               -- ② 고객별로 묶음
HAVING COUNT(*) >= 2;              -- ③ 묶은 결과(주문수)로 거름
```

### WHERE vs HAVING

| | WHERE | HAVING |
|---|---|---|
| 언제 실행 | GROUP BY **전** | GROUP BY **후** |
| 거르는 대상 | **행** 하나하나 | **그룹(바구니)** |
| 집계 함수 사용 | ❌ 불가 | ✅ 가능 |
| 예시 | `WHERE price >= 5000` | `HAVING COUNT(*) >= 2` |

```sql
-- ❌ WHERE가 실행될 때는 아직 그룹이 없어서 COUNT를 계산할 수 없음
SELECT customer_id, COUNT(*) FROM orders WHERE COUNT(*) >= 2 GROUP BY customer_id;
```

> [!TIP]
> 구분법: 조건에 **집계 함수**(`COUNT`, `SUM`, `AVG` …)가 들어가면 HAVING, 아니면 WHERE. 집계 함수가 없는 조건은 WHERE에 두는 게 빠르고 깔끔합니다.

## 4. 쿼리 실행 순서 (완성판)

4강 표에 GROUP BY와 HAVING이 추가됩니다.

| 쓰는 순서 | 실행 순서 | 하는 일 |
|---|---|---|
| SELECT | 5 | 보여 줄 열, 별칭 |
| FROM | **1** | 테이블 가져오기 |
| WHERE | **2** | 행 거르기 |
| GROUP BY | **3** | 바구니에 나누기 |
| HAVING | **4** | 바구니 거르기 |
| ORDER BY | 6 | 정렬 |
| LIMIT | 7 | 개수 자르기 |

외우는 법: **프(FROM) 웨(WHERE) 그(GROUP) 해(HAVING) 셀(SELECT) 오(ORDER) 리(LIMIT)**.

> [!NOTE]
> MySQL은 HAVING에서 SELECT 별칭(`HAVING 주문수 >= 2`)을 봐주지만, Oracle 등 다른 DB에서는 오류가 납니다. 실행 순서상 HAVING이 SELECT보다 먼저이기 때문입니다. **HAVING에는 집계식을 그대로**(`HAVING COUNT(*) >= 2`) 쓰는 습관을 들이세요.

## 5. 실무에서는 이렇게 쓰입니다

- "카테고리별 매출", "지역별 고객 수", "월별 가입자 수" → `GROUP BY`
- "VIP 고객(3회 이상 구매)", "매출 100만 원 이상인 지점" → `HAVING`
- 데이터 분석 면접 SQL 문제의 절반 이상이 GROUP BY + HAVING 조합입니다.

---

## 실습 문제

별칭은 따옴표 없이, 실행 후 **행 수와 첫 행이 힌트와 맞는지** 확인하세요. 다 풀면 **"7강 답안 제출"**.

**복습.** 맨 위 0번의 ①~④ 쿼리 결과가 각각 몇 행인지 적고, 왜 그런지 한 줄로 설명하세요.

> ① 행 / ② 행 / ③ 행 / ④ 행
> 이유:

**문제 1.** 분류별 메뉴 수를 조회하세요. 열 이름은 `분류`, `메뉴수`. (결과 3행)

```sql

```

**문제 2.** 분류별 평균 가격(정수 반올림)을 조회하고 **평균 가격이 높은 순**으로 정렬하세요. 열 이름은 `분류`, `평균가격`. (결과 3행, 첫 행 논커피 5167)

```sql

```

**문제 3.** 지역별 고객 수를 조회하고, **고객 수가 많은 순**, 같으면 **지역 이름 순**으로 정렬하세요. 열 이름은 `지역`, `고객수`. (결과 4행, 첫 행 서울 5)

```sql

```

**문제 4.** 결제수단별 주문 수를 많은 순으로 조회하세요. 열 이름은 `결제수단`, `주문수`. (결과 3행, 첫 행 카드 10)

```sql

```

**문제 5.** **회원 주문만** 대상으로, 고객번호별 주문 횟수를 조회하세요. 주문 횟수가 많은 순, 같으면 고객번호 순. 열 이름은 `고객번호`, `주문횟수`. (결과 9행, 첫 행 1번 고객 3회)

```sql

```

**문제 6.** `order_items`에서 메뉴번호별 총 판매 수량을 많은 순으로 **상위 3개**만 조회하세요. 같으면 메뉴번호 순. 열 이름은 `메뉴번호`, `판매수량`. (결과 3행, 첫 행 2번 메뉴 7개)
→ 메뉴번호 대신 메뉴 이름을 보려면 두 테이블을 합쳐야 합니다. 그게 8강 JOIN입니다.

```sql

```

**문제 7.** 가격대별 메뉴 수를 조회하세요. 가격대는 5강 7번과 같이 3000원 미만 `저가`, 5000원 미만 `중가`, 나머지 `고가`. 열 이름은 `가격대`, `메뉴수`. (결과 3행: 고가 8, 저가 1, 중가 3)

```sql

```

**문제 8.** **2번 이상** 주문한 회원의 고객번호와 주문 횟수를 조회하세요. 열 이름은 `고객번호`, `주문횟수`. (결과 5행)

```sql

```

**문제 9.** 평균 가격이 **5000원 이상**인 분류와 그 평균 가격(정수 반올림)을 조회하세요. 열 이름은 `분류`, `평균가격`. (결과 2행)

```sql

```

**문제 10. (함정 문제)** 아래 쿼리를 실행해 보고 오류 메시지와 이유를 적은 뒤, 8번과 같은 결과가 나오도록 고치세요.

```sql
SELECT customer_id, COUNT(*) AS 주문횟수
FROM orders
WHERE COUNT(*) >= 2
GROUP BY customer_id;
```

오류 메시지와 이유:
>

고친 쿼리:

```sql

```

## 이해 확인 질문

1. `GROUP BY category`를 하면 SELECT에 `name`을 쓸 수 없는 이유는 무엇인가요?
2. "가격이 5000원 이상인 메뉴만 대상으로, 분류별 메뉴 수"를 구할 때 `price >= 5000` 조건은 WHERE와 HAVING 중 어디에 써야 하나요? 이유는?
3. 아래 쿼리 각 줄의 **실행 순서**를 번호로 적어 보세요.
   ```sql
   SELECT category, COUNT(*)    -- ?
   FROM menu                    -- ?
   WHERE price >= 4000          -- ?
   GROUP BY category            -- ?
   HAVING COUNT(*) >= 3         -- ?
   ORDER BY category;           -- ?
   ```

Related: [6강 집계 함수](01-06_집계_함수.md) · [5강 계산과 함수](01-05_계산과_함수.md) · [오답노트](../오답노트.md)
Up: [1단계 목차](INDEX.md)
