-- ============================================================
-- 거래 날짜 무결성 검증 (SQLite)
-- 규칙: 가입일(signup_at) <= 개설일(opened_at) <= 거래일시(txn_at)
-- 입력 테이블 txn: data/transaction_date_classification.csv 를 적재
--   txn_id, account_id, customer_id, signup_at, opened_at, txn_at, amt
-- 날짜는 'YYYY-MM-DD HH:MM:SS' 형식이라 문자열 비교가 시간순과 일치함
-- ============================================================

-- 1) 규칙별 위반 건수 (두 규칙을 독립적으로 집계)
SELECT
    COUNT(*)                                              AS total_txn,
    SUM(txn_at < opened_at)                               AS txn_before_open,
    SUM(opened_at < signup_at)                            AS open_before_signup,
    SUM(txn_at < opened_at AND opened_at < signup_at)     AS both_violated,
    SUM(txn_at >= opened_at AND opened_at >= signup_at)   AS valid_order,
    SUM(amt IS NULL)                                      AS amount_missing
FROM txn;

-- 2) 교차표: 한 거래가 두 규칙을 동시에 어기는지 확인
SELECT
    CASE WHEN txn_at < opened_at     THEN '개설 전 거래 O' ELSE '개설 전 거래 X' END AS rule_b,
    CASE WHEN opened_at < signup_at  THEN '가입 전 개설 O' ELSE '가입 전 개설 X' END AS rule_a,
    COUNT(*) AS n
FROM txn
GROUP BY rule_b, rule_a
ORDER BY rule_b, rule_a;

-- 3) 필터링 후 남는 표본과 금액 (결측 금액은 합계에서 제외)
SELECT
    CASE WHEN txn_at < opened_at THEN '개설 전 거래' ELSE '개설 후 거래' END AS grp,
    COUNT(*)              AS n_txn,
    COUNT(amt)            AS n_amount_known,
    ROUND(SUM(amt), 2)    AS amount_usd
FROM txn
GROUP BY grp;

-- 4) 기간 범위 비교: 거래일 범위와 개설일 범위가 겹치는지
SELECT MIN(txn_at) AS txn_min, MAX(txn_at) AS txn_max,
       MIN(opened_at) AS open_min, MAX(opened_at) AS open_max
FROM txn;

-- 5) 계좌 개설연도 분포 (거래가 몰린 2019년 이후 개설 계좌가 대부분인지 확인)
SELECT SUBSTR(opened_at, 1, 4) AS open_year,
       COUNT(DISTINCT account_id) AS n_account
FROM txn
GROUP BY open_year
ORDER BY open_year;
