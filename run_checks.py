import re
from pathlib import Path
from sqlalchemy import text
from src.db import get_engine

# Runs every "-- check:" block in checks.sql and reports PASS (0 rows) or FAIL.
sql = Path(__file__).with_name("checks.sql").read_text(encoding="utf-8")
blocks = re.split(r"^-- check:\s*", sql, flags=re.M)[1:]
engine = get_engine()
failed = 0
with engine.connect() as con:
    for block in blocks:
        name, _, query = block.partition("\n")
        n = len(con.execute(text(query.strip().rstrip(";"))).fetchall())
        failed += n > 0
        print(("PASS" if n == 0 else "FAIL"), name.strip(), "" if n == 0 else f"({n} bad rows)")
raise SystemExit(1 if failed else 0)
