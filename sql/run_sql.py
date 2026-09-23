"""CSV를 SQLite 메모리 DB에 적재하고 date_integrity_check.sql을 순서대로 실행한다.
실행: python sql/run_sql.py  (프로젝트 루트에서)
"""
import sqlite3
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
df = pd.read_csv(ROOT / "data" / "transaction_date_classification.csv", encoding="utf-8-sig")

# 금액 문자열("$2,252.75") → 숫자, 변환 실패는 결측으로 둔다
df["amt"] = pd.to_numeric(
    df["거래금액_USD"].astype(str).str.replace(r"[$,]", "", regex=True), errors="coerce"
)
df = df.rename(columns={
    "거래번호": "txn_id", "계좌번호": "account_id", "고객번호": "customer_id",
    "가입일": "signup_at", "개설일": "opened_at", "거래일시": "txn_at",
})[["txn_id", "account_id", "customer_id", "signup_at", "opened_at", "txn_at", "amt"]]

con = sqlite3.connect(":memory:")
df.to_sql("txn", con, index=False)

sql_text = (ROOT / "sql" / "date_integrity_check.sql").read_text(encoding="utf-8")
for i, stmt in enumerate(s for s in sql_text.split(";") if "SELECT" in s.upper()):
    print(f"\n[Query {i + 1}]")
    print(pd.read_sql(stmt, con).to_string(index=False))
