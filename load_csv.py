"""Re-load a Bronze table from the CERT r4.2 CSV files (needed only if Bronze must be rebuilt).

Usage:  python -m src.ingest.load_csv logon  C:\\data\\logon.csv
        python -m src.ingest.load_csv device C:\\data\\device.csv

Bronze is the only place where source files enter the warehouse. The original CERT files are not committed
(see docs/data_source_register.csv for where to download them). The project's current Bronze tables were loaded
once from those files and already hold the data, so this script is a reproducibility aid, not part of the daily run.
"""
import sys
from sqlalchemy import text
from src.db import get_engine

TABLES = {"logon": "bronze.logon", "device": "bronze.device"}
LOAD_VIEWS = {"logon": "bronze.v_logon_load", "device": "bronze.v_device_load"}

if len(sys.argv) != 3 or sys.argv[1] not in TABLES:
    raise SystemExit("usage: python -m src.ingest.load_csv <logon|device> <path-to-csv>")
name, path = sys.argv[1], sys.argv[2]
target = TABLES[name]
engine = get_engine()
with engine.begin() as con:
    # BULK INSERT runs on the SQL Server machine, so that machine must be able to read the path.
    con.execute(text(f"TRUNCATE TABLE {target}"))
    con.execute(text(
        f"BULK INSERT {LOAD_VIEWS[name]} FROM '{path.replace(chr(39), chr(39) * 2)}' "
        "WITH (FIRSTROW = 2, FORMAT = 'CSV', FIELDTERMINATOR = ',', TABLOCK)"))
    con.execute(text(f"UPDATE {target} SET source_file = :p"), {"p": path})
    rows = con.execute(text(f"SELECT COUNT(*) FROM {target}")).scalar()
print("Loaded", rows, "rows into", target)
