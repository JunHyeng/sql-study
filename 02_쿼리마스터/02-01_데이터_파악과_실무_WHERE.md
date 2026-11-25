---
title: 2단계 1강 데이터 파악과 실무 WHERE 패턴
date: 2026-11-24
tags: [sql, 2단계, where, 날짜, 인덱스]
---

# 2단계 1강: 데이터 파악과 실무 WHERE 패턴

> 시니어의 한마디: "쿼리는 문법이 맞아도 **숫자가 틀리면** 실패입니다. 틀린 숫자는 오류 메시지도 안 띄우고 보고서에 그대로 실립니다."

먼저 [베라몰 DB 안내](02-00_베라몰_DB_안내.md)대로 `shop` DB를 설치하세요. 이번 강의 모든 쿼리는 `USE shop;` 상태에서 실행합니다.

## 오늘의 목표

- 처음 보는 테이블을 받았을 때 **5분 안에 데이터를 파악**하는 순서를 안다.
- DATETIME 컬럼에서 **날짜 범위를 정확하게** 거를 수 있다. (BETWEEN 함정)
- WHERE에서 컬럼에 함수를 씌우면 왜 느려지는지(인덱스) 설명할 수 있다.
- 요청서의 말을 정확한 조건으로 옮길 수 있다. ("매출" = 배송완료만)

## 1. 처음 받은 테이블, 이 순서로 파악하기

실무에서는 테이블 설명서가 없거나 틀린 경우가 많습니다. 쿼리를 쓰기 전에 **데이터부터 봅니다.**

| 순서 | 확인할 것 | 쿼리 예시 |
|---|---|---|
| ① 크기 | 몇 행인가 | `SELECT COUNT(*) FROM orders;` |
| ② 생김새 | 실제 값이 어떻게 생겼나 | `SELECT * FROM orders LIMIT 10;` |
| ③ 기간 | 데이터가 언제부터 언제까지인가 | `SELECT MIN(ordered_at), MAX(ordered_at) FROM orders;` |
| ④ 범주 값 | 어떤 값들이 있고 몇 개씩인가 | `SELECT status, COUNT(*) FROM orders GROUP BY status;` |
| ⑤ 빈 값 | NULL이 얼마나 있나 | `SELECT COUNT(*) - COUNT(email) FROM customers;` |
| ⑥ 중복 | 유일해야 할 값이 중복되나 | `SELECT name, COUNT(*) FROM customers GROUP BY name HAVING COUNT(*) > 1;` |

④를 건너뛰면 `status = '완료'`라고 썼는데 실제 값은 `'배송완료'`라서 **0건**이 나오는 사고가 납니다. 오류가 아니라 0건이라 더 무섭습니다.

> [!TIP]
> 1단계 10강에서 결산 경험을 살려 검산을 했듯이, 2단계에서는 **"이 숫자가 말이 되나?"**를 항상 먼저 생각하세요. 예를 들어 월 매출이 전체 매출보다 크면 어딘가 잘못된 것입니다.

## 2. 날짜 범위: BETWEEN 함정 (가장 중요)

`ordered_at`은 **DATETIME**(날짜 + 시간)입니다.

```sql
-- ❌ 12월 주문 수를 구하려는 의도
SELECT COUNT(*) FROM orders
WHERE ordered_at BETWEEN '2025-12-01' AND '2025-12-31';
```

`'2025-12-31'`은 DATETIME과 비교될 때 **`2025-12-31 00:00:00`**으로 바뀝니다. 그래서 12월 31일 0시 1분 이후 주문이 **전부 빠집니다.** 오류도 안 납니다.

```sql
-- ✅ 실무 표준: 시작일 이상(>=), 다음 달 1일 미만(<)
SELECT COUNT(*) FROM orders
WHERE ordered_at >= '2025-12-01'
  AND ordered_at <  '2026-01-01';
```

| 방법 | 12월 31일 오후 주문 | 비고 |
|---|---|---|
| `BETWEEN '2025-12-01' AND '2025-12-31'` | ❌ 빠짐 | DATE 컬럼에서는 괜찮지만 DATETIME에서는 위험 |
| `BETWEEN '2025-12-01' AND '2025-12-31 23:59:59'` | 대부분 포함 | 밀리초가 있는 DB에서는 또 빠질 수 있음 |
| `>= '2025-12-01' AND < '2026-01-01'` | ✅ 포함 | **어떤 자료형이든 항상 정확** |

> [!WARNING]
> 1단계 카페 DB의 `order_date`는 DATE(시간 없음)라서 BETWEEN이 문제없었습니다. 실무 주문 테이블은 대부분 DATETIME입니다. **날짜 범위는 `>=` 와 `<` 조합으로 쓰는 습관**을 지금부터 들이세요.

## 3. WHERE에서 컬럼에 함수를 씌우지 않기 (인덱스)

### 인덱스란?

책 맨 뒤의 **찾아보기(색인)**와 같습니다. "SQL" 단어가 나오는 페이지를 찾을 때 책 전체를 넘기지 않고 색인에서 바로 페이지 번호를 찾습니다. `shop` DB에는 `ordered_at`에 인덱스가 만들어져 있습니다.

```sql
-- ❌ 컬럼에 함수를 씌움 → 모든 행의 MONTH()를 계산해 봐야 함 (색인을 못 씀)
WHERE YEAR(ordered_at) = 2025 AND MONTH(ordered_at) = 11

-- ✅ 컬럼은 그대로, 값 쪽에서 범위를 만듦 → 색인으로 바로 찾음
WHERE ordered_at >= '2025-11-01' AND ordered_at < '2025-12-01'
```

결과는 같지만, 주문이 수천만 건인 실무 DB에서는 몇 초와 몇 분의 차이가 납니다. **"컬럼은 가공하지 말고, 비교하는 값을 가공한다"**가 원칙입니다.

같은 이유로:

| 느린 쓰기 | 빠른 쓰기 |
|---|---|
| `WHERE DATE(ordered_at) = '2025-12-24'` | `WHERE ordered_at >= '2025-12-24' AND ordered_at < '2025-12-25'` |
| `WHERE LEFT(name, 1) = '김'` | `WHERE name LIKE '김%'` (앞부분 고정 LIKE는 색인 사용 가능) |
| `WHERE name LIKE '%우'` | (뒤 글자 검색은 색인 사용 불가, 꼭 필요할 때만) |

### EXPLAIN: DB가 어떻게 찾는지 보기

쿼리 앞에 `EXPLAIN`을 붙이면 실행하지 않고 **실행 계획**만 보여 줍니다.

```sql
EXPLAIN SELECT * FROM orders WHERE MONTH(ordered_at) = 11;
EXPLAIN SELECT * FROM orders WHERE ordered_at >= '2025-11-01' AND ordered_at < '2025-12-01';
```

결과의 `type`과 `rows` 열을 비교해 보세요. `ALL`은 **전체를 다 읽음**, `range`는 **색인으로 범위만 읽음**이고, `rows`는 읽을 것으로 예상하는 행 수입니다. (데이터가 작으면 DB가 판단해서 전체를 읽기도 합니다. 지금은 "이런 걸 볼 수 있다" 정도만 알면 됩니다)

## 4. 요청서의 말을 조건으로 옮기기

| 요청서 표현 | 실제 조건 | 빠뜨리면 |
|---|---|---|
| "매출" | `status = '배송완료'` | 취소·반품까지 매출로 잡힘 |
| "11월" | `ordered_at >= '2025-11-01' AND ordered_at < '2025-12-01'` | BETWEEN 함정 |
| "수신 동의한 고객" | `marketing_agree = 1` | 동의 안 한 고객에게 광고 발송 (법적 문제) |
| "서울·경기의 동의 고객" | `city IN ('서울','경기') AND marketing_agree = 1` | OR를 괄호 없이 쓰면 AND가 먼저 묶임 (1단계 2강) |

> [!NOTE]
> 요청이 애매하면 쿼리를 짜기 전에 **되묻는 것**이 시니어입니다. "매출에 반품 포함인가요?", "11월은 주문일 기준인가요, 배송일 기준인가요?" 이번 강의 문제는 기준을 명시해 두었지만, 실무에서는 질문 한 번이 재작업 몇 시간을 줄입니다.

---

## 실무 문제

`USE shop;` 상태에서 푸세요. 각 문제는 **팀장님 요청** 형식입니다. 이번 강부터는 행 수 힌트를 일부만 줍니다. **숫자가 상식적인지 스스로 검증**하세요. 다 풀면 **"2단계 1강 답안 제출"**.

### ★ 기본

**문제 1.** "주문 데이터가 언제부터 언제까지 있는지, 총 몇 건인지 알려 주세요." 열 이름 `첫주문`, `마지막주문`, `주문수`. (1행)

```sql
select

min(ordered_at) as 첫주문,

max(ordered_at) as 마지막주문,

count(*) as 주문수

from orders;
```

**문제 2.** "주문 상태 값이 뭐가 있는지, 상태별로 몇 건인지 많은 순으로 보여 주세요." 열 이름 `상태`, `주문수`.

```sql
select

status as 상태,

count(*) as 주문수

from orders

group by status

order by 주문수 desc, 상태;
```

**문제 3.** "12월 주문이 총 몇 건이에요? (상태 상관없이)" 아래 두 쿼리를 **둘 다** 실행해 보고 결과를 비교한 뒤, 어느 쪽이 맞는지와 이유를 적으세요.

```sql
-- (가)
SELECT COUNT(*) FROM orders WHERE ordered_at BETWEEN '2025-12-01' AND '2025-12-31';
-- (나)
SELECT COUNT(*) FROM orders WHERE ordered_at >= '2025-12-01' AND ordered_at < '2026-01-01';
```

> (가) 건 / (나) 건 / 맞는 쪽과 이유:  (나) / 이유 : BETWEEN '2025-12-01' AND '2025-12-31'는 datetime으로 비교될 때 '2025-12-31 00;00:00'으로 바껴서, 그 이후 시간 데이터는 다 누락되어버려서 (나)의 코드 처럼 범위를 확실하게 지정해야함

**문제 4.** "마케팅 수신에 동의했는데 **이메일이 없는** 고객이 몇 명이에요? 이메일 캠페인 대상에서 빠지는 인원이라서요." 열 이름 `이메일없는동의고객`.

```sql
select

count(*) as 이메일없는동의고객

from customers

where email is null and marketing_agree = 1;
```

### ★★ 실무

**문제 5.** "2025년 11월 **매출**과 매출이 발생한 주문 건수를 알려 주세요." (매출 정의는 [DB 안내](02-00_베라몰_DB_안내.md) 참고, 날짜 조건에 함수 쓰지 말 것) 열 이름 `주문건수`, `매출`.

```sql
select

count(distinct o.order_id) as 주문건수,

sum(oi.unit_price * oi.quantity) as 매출

from orders o

join order_items oi on o.order_id = oi.order_id

where

o.status = '배송완료'

and o.ordered_at >= '2025-11-01'

and ordered_at < '2025-12-01';
```

**문제 6.** "다음 달 지역 이벤트 대상자 수가 필요해요. **서울이나 경기**에 살고, **마케팅 수신 동의**했고, **2025년에 가입**한 고객이 몇 명이죠?" 열 이름 `대상자수`. (26명)

```sql
select

count(*) as 대상자수

from customers

where

city in ('서울', '경기')

and marketing_agree = 1

and signup_date >= '2025-01-01'

and signup_date < '2026-01-01';
```

**문제 7.** "김씨 고객 중에 **동명이인**이 있으면 이름과 인원을 알려 주세요. 고객센터에서 헷갈린대요." 열 이름 `이름`, `인원`. (이름 순)

```sql
select

name as 이름,

count(*) as 인원

from customers

where

name like '김%'

group by name

having count(*) >= 2

order by 이름;
```

**문제 8.** "**단종된 상품**(is_active = 0)이 마지막으로 팔린 게 언제예요? 상품명, 마지막 주문일시, 판매된 주문상세 건수를 알려 주세요." 열 이름 `상품명`, `마지막주문일시`, `판매건수`. (상태 상관없이)

```sql
select

p.name as 상품명,

max(o.ordered_at) as 마지막주문일시,

count(*) as 판매건수

from products p

join order_items oi on p.product_id = oi.product_id

join orders o on oi.order_id = o.order_id

where is_active = 0

group by p.product_id, p.name;
```

### ★★★ 까다로움

**문제 9.** "주문 상세 중에 **정가보다 싸게(할인해서) 팔린 건**이 몇 건이고, 전체 주문 상세의 몇 %예요?" 열 이름 `전체건수`, `할인건수`, `할인비율`(소수 첫째 자리 %). 힌트: 쿼리를 두 개로 나눠 구한 뒤 계산해도 됩니다. 한 번에 구하는 방법은 3강에서 배웁니다.

```sql

```

**문제 10.** "저녁 시간대(18시~23시대) 주문이 앱과 웹에서 각각 몇 건이에요?" 열 이름 `채널`, `저녁주문수`. 힌트: 시간만 꺼내는 함수 `HOUR(ordered_at)`. (전체 상태 대상)

```sql

```

### 코드 리뷰

**문제 11.** 신입 사원이 아래 쿼리를 올렸습니다. **문제점 2가지 이상**을 찾고 고친 쿼리를 쓰세요. (요청: "2025년 11월 배송완료 주문 수")

```sql
SELECT COUNT(*)
FROM orders
WHERE YEAR(ordered_at) = 2025 AND MONTH(ordered_at) = 11
   OR status = '배송완료';
```

문제점:
>

고친 쿼리:

```sql

```

**문제 12. (EXPLAIN 관찰)** 3번 본문의 EXPLAIN 두 개를 실행하고 각각의 `type`과 `rows` 값을 적어 보세요.

> MONTH() 사용: type = / rows =
> 범위 조건: type = / rows =

## 이해 확인 질문

1. DATETIME 컬럼에서 `BETWEEN '2025-12-01' AND '2025-12-31'`이 위험한 이유는 무엇인가요?
2. `WHERE MONTH(ordered_at) = 11`보다 범위 조건이 빠른 이유를 "색인"에 빗대어 설명해 보세요.
3. 처음 보는 테이블을 받았을 때, 쿼리를 짜기 전에 확인할 것 3가지를 말해 보세요.

Related: [베라몰 DB 안내](02-00_베라몰_DB_안내.md) · [1단계 2강 WHERE](../01_SQL기초/01-02_WHERE로_조건_걸기.md) · [오답노트](../오답노트.md)
Up: [2단계 목차](INDEX.md)
