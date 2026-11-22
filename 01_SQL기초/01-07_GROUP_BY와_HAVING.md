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

> ① 12행 / ② 1행 / ③ 4행 / ④ 1행
> 이유: 행단위 함수 ROUND(), 집계 함수SUM()을 사용해서 다르게 나옴. 집계 함수는 결과 합계값만 나오기 때문에 행이 합계 칸 1개만 나옵니다.

**문제 1.** 분류별 메뉴 수를 조회하세요. 열 이름은 `분류`, `메뉴수`. (결과 3행)

```sql
select category as 분류, count(*) as 매뉴수 from menu group by category;
```

**문제 2.** 분류별 평균 가격(정수 반올림)을 조회하고 **평균 가격이 높은 순**으로 정렬하세요. 열 이름은 `분류`, `평균가격`. (결과 3행, 첫 행 논커피 5167)

```sql
select category as 분류, ROUND(avg(price)) as 평균가격 from menu group by category order by 평균가격 desc;
```

**문제 3.** 지역별 고객 수를 조회하고, **고객 수가 많은 순**, 같으면 **지역 이름 순**으로 정렬하세요. 열 이름은 `지역`, `고객수`. (결과 4행, 첫 행 서울 5)

```sql
select city as 지역, count(*) as 고객수 from customers group by city order by 고객수 desc, 지역 asc;
```

**문제 4.** 결제수단별 주문 수를 많은 순으로 조회하세요. 열 이름은 `결제수단`, `주문수`. (결과 3행, 첫 행 카드 10)

```sql
select payment as 결제수단, count(*) as 주문수 from orders group by payment order by 주문수 desc;
```

**문제 5.** **회원 주문만** 대상으로, 고객번호별 주문 횟수를 조회하세요. 주문 횟수가 많은 순, 같으면 고객번호 순. 열 이름은 `고객번호`, `주문횟수`. (결과 9행, 첫 행 1번 고객 3회)

```sql
select customer_id as 고객번호, count(*) as 주문횟수 from orders where customer_id is not null group by customer_id;
```

**문제 6.** `order_items`에서 메뉴번호별 총 판매 수량을 많은 순으로 **상위 3개**만 조회하세요. 같으면 메뉴번호 순. 열 이름은 `메뉴번호`, `판매수량`. (결과 3행, 첫 행 2번 메뉴 7개)
→ 메뉴번호 대신 메뉴 이름을 보려면 두 테이블을 합쳐야 합니다. 그게 8강 JOIN입니다.

```sql
select menu_id as 메뉴번호, sum(quantity) as 판매수량 from order_items group by menu_id order by 판매수량 desc, 메뉴번호 asc limit 3;
```

**문제 7.** 가격대별 메뉴 수를 조회하세요. 가격대는 5강 7번과 같이 3000원 미만 `저가`, 5000원 미만 `중가`, 나머지 `고가`. 열 이름은 `가격대`, `메뉴수`. (결과 3행: 고가 8, 저가 1, 중가 3)

```sql
select

case

when price < 3000 then '저가'

when price < 5000 then '중가'

else '고가'

end as 가격대,

count(*) as 메뉴수

from menu

group by 가격대

order by 메뉴수 desc;
```

**문제 8.** **2번 이상** 주문한 회원의 고객번호와 주문 횟수를 조회하세요. 열 이름은 `고객번호`, `주문횟수`. (결과 5행)

```sql
select

customer_id as 고객번호,

count(*) as 주문횟수

from orders

where customer_id is not null

group by customer_id

having count(*) >= 2;
```

**문제 9.** 평균 가격이 **5000원 이상**인 분류와 그 평균 가격(정수 반올림)을 조회하세요. 열 이름은 `분류`, `평균가격`. (결과 2행)

```sql
select

category as 분류,

round(avg(price)) as 평균가격

from menu

group by 분류

having 평균가격 >= 5000

order by 평균가격 desc;
```

**문제 10. (함정 문제)** 아래 쿼리를 실행해 보고 오류 메시지와 이유를 적은 뒤, 8번과 같은 결과가 나오도록 고치세요.

```sql
SELECT customer_id, COUNT(*) AS 주문횟수
FROM orders
WHERE COUNT(*) >= 2
GROUP BY customer_id;
```

오류 메시지와 이유:
>오류 메시지 : 'SQL 오류 [1111] [HY000]: Invalid use of group function'
>이유 : where절에는 집계 함수를 못씀.

고친 쿼리:

```sql
SELECT customer_id, COUNT(*) AS 주문횟수

FROM orders

GROUP BY customer_id

having COUNT(*) >= 2;
```

## 이해 확인 질문

1. `GROUP BY category`를 하면 SELECT에 `name`을 쓸 수 없는 이유는 무엇인가요?
	그룹 기준이랑 집계 함수만 가능함. name을 쓰게 되면 기준이 여러개가 되어서 사용불가
2. "가격이 5000원 이상인 메뉴만 대상으로, 분류별 메뉴 수"를 구할 때 `price >= 5000` 조건은 WHERE와 HAVING 중 어디에 써야 하나요? 이유는?
	분류별 메뉴 수 있므로, having 사용
3. 아래 쿼리 각 줄의 **실행 순서**를 번호로 적어 보세요.
   ```sql
   SELECT category, COUNT(*)    -- 5
   FROM menu                    -- 1
   WHERE price >= 4000          -- 2
   GROUP BY category            -- 3
   HAVING COUNT(*) >= 3         -- 4
   ORDER BY category;           -- 6
   ```

---

## 채점 결과 (2026-11-22)

**복습 정답, 쿼리 8.5 / 10, 이해 확인 2 / 3 → WHERE vs HAVING 재확인 후 8강 진행**

| 문제 | 결과 | 코멘트 |
|---|---|---|
| 복습 | 정답 | 행 단위 함수 N행 → N행, 집계 함수 N행 → 1행. 6강 확인 3번 해결 ✅ |
| 1 | 정답 (오타) | 별칭 `매뉴수` → `메뉴수`. 보고서 머리글 오타는 실무에서 그대로 노출되니 실행 후 머리글도 한 번 보세요. |
| 2~4 | 정답 | 3번 정렬 기준 두 개까지 정확합니다. |
| 5 | **부분 정답** | `ORDER BY 주문횟수 DESC, 고객번호`가 빠졌습니다. ORDER BY가 없으면 순서가 보장되지 않습니다. (4강 LIMIT 내용과 같은 원리) |
| 6 | 정답 | GROUP BY + SUM + ORDER BY 두 기준 + LIMIT, 1단계 문법을 전부 조합했습니다. |
| 7 | 정답 | CASE 결과로 묶기, 정확합니다. |
| 8 | 정답 | WHERE(행 거르기) → GROUP BY → HAVING(그룹 거르기) 완벽합니다. |
| 9 | 정답 (주의점) | 아래 피드백 2 |
| 10 | **부분 정답** | 오류 메시지와 이유까지 정확히 적었습니다 👍 고친 쿼리는 아래 피드백 1 |
| 확인 1 | 정답 | |
| 확인 2 | **오답** | 아래 피드백 3 (가장 중요) |
| 확인 3 | 정답 | 5-1-2-3-4-6 정확합니다. |

### 피드백 1: 10번, "8번과 같은 결과"가 아니라 6행이 나옵니다

고친 쿼리에서 `WHERE customer_id IS NOT NULL`이 빠져서, **비회원 주문(NULL) 2건이 한 그룹**으로 묶이고 `COUNT(*) = 2`라서 HAVING도 통과합니다. 결과가 5행이 아니라 **6행**(고객번호 NULL, 2회 포함)이 됩니다.

```sql
SELECT customer_id, COUNT(*) AS 주문횟수
FROM orders
WHERE customer_id IS NOT NULL     -- 이 줄이 필요
GROUP BY customer_id
HAVING COUNT(*) >= 2;
```

이번 강 2번 "NULL도 하나의 그룹이 된다"의 실제 사례입니다. 실행 후 **행 수(5행)를 힌트와 비교**했다면 잡을 수 있었습니다.

### 피드백 2: 9번, HAVING에 별칭과 반올림 값을 쓴 것

`GROUP BY 분류`, `HAVING 평균가격 >= 5000`은 MySQL에서는 돌아가지만 두 가지 주의점이 있습니다.

1. **다른 DB에서는 오류**: 실행 순서상 GROUP BY·HAVING이 SELECT보다 먼저라 별칭이 아직 없습니다. Oracle로 옮기면 깨집니다.
2. **반올림된 값으로 비교됨**: `평균가격`은 `ROUND(AVG(price))`라서, 평균이 4999.6원이면 반올림해서 5000이 되어 **통과해 버립니다.** "평균 5000원 이상"이라는 기준과 달라집니다.

```sql
SELECT category AS 분류, ROUND(AVG(price)) AS 평균가격
FROM menu
GROUP BY category                 -- 원래 컬럼
HAVING AVG(price) >= 5000         -- 반올림 전 값으로 비교
ORDER BY 평균가격 DESC;           -- ORDER BY는 SELECT 뒤라 별칭 OK
```

### 피드백 3: `price >= 5000`은 WHERE에 써야 합니다

"분류별"이라는 말이 있어서 HAVING이라고 생각하셨는데, 기준은 **조건 안에 집계 함수가 있느냐**입니다.

- `price >= 5000` → `price`는 **메뉴 한 행 한 행의 값**입니다. 집계 함수가 없음 → **WHERE**
- "5000원 이상 메뉴만 남긴 다음(WHERE) → 분류별로 묶어서 센다(GROUP BY)" 순서입니다.

```sql
SELECT category, COUNT(*) AS 메뉴수
FROM menu
WHERE price >= 5000      -- ① 행 거르기
GROUP BY category;       -- ② 남은 행을 묶어서 세기
-- 결과: 논커피 3, 디저트 3, 커피 2
```

HAVING에 `price >= 5000`을 쓰면, 바구니(그룹) 안에 price가 여러 개라 **어느 price로 비교할지 정할 수 없습니다.** (확인 1번의 `name`과 같은 이유)

### 재확인 (2026-11-22)

- 카드 결제 주문만, 고객별 주문 수 → `payment = '카드'`는 WHERE ✅
- 평균 가격 5000원 넘는 분류 → `AVG(price) > 5000`은 HAVING ✅
- 10월 5일 이후(WHERE) + 결제수단별 3건 이상(HAVING) ✅
- 판정: **WHERE vs HAVING 구분 이해 → 7강 통과**

Related: [8강 JOIN 입문](01-08_JOIN_입문.md) · [6강 집계 함수](01-06_집계_함수.md) · [5강 계산과 함수](01-05_계산과_함수.md) · [오답노트](../오답노트.md)
Up: [1단계 목차](INDEX.md)
