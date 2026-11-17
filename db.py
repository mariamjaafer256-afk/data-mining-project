import os
import urllib.parse
from sqlalchemy import create_engine

try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass


def get_engine():
    # Connection settings come from .env (never hard-code passwords).
    conn = os.environ.get("SQLSERVER_CONN") or (
        "DRIVER={ODBC Driver 18 for SQL Server};"
        "SERVER=localhost\\INSTANCE2022;DATABASE=InsiderThreat;"
        "Trusted_Connection=yes;TrustServerCertificate=yes;"
    )
    url = "mssql+pyodbc:///?odbc_connect=" + urllib.parse.quote_plus(conn)
    return create_engine(url, fast_executemany=True)
