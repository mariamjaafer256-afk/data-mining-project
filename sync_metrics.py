from pathlib import Path
import yaml
from sqlalchemy import text
from src.db import get_engine

# Copies semantic/metrics.yml into semantic.metric_catalog (the YAML file is the source of truth),
# then runs every metric's validation query. Existing catalog rows that are not in the YAML are kept.
metrics = yaml.safe_load(Path("semantic/metrics.yml").read_text(encoding="utf-8"))["metrics"]
engine = get_engine()
with engine.begin() as con:
    for m in metrics:
        p = {"n": m["name"], "l": m["label"], "d": m["definition"], "o": m["owner"], "g": m["grain"],
             "s": m["sql"], "dim": ", ".join(m["dimensions"]), "np": m["null_policy"], "v": m["validation_query"]}
        updated = con.execute(text(
            "UPDATE semantic.metric_catalog SET label=:l, definition=:d, owner=:o, grain=:g, sql_expression=:s, "
            "dimensions=:dim, null_policy=:np, validation_query=:v, description=LEFT(:d, 255), "
            "calculation_logic=:s, updated_at=SYSDATETIME() WHERE metric_name=:n"), p).rowcount
        if updated == 0:
            con.execute(text(
                "INSERT semantic.metric_catalog (metric_name, label, definition, owner, grain, sql_expression, "
                "dimensions, null_policy, validation_query, description, calculation_logic, updated_at) "
                "VALUES (:n, :l, :d, :o, :g, :s, :dim, :np, :v, LEFT(:d, 255), :s, SYSDATETIME())"), p)
print("Synced", len(metrics), "metrics")

with engine.connect() as con:
    for m in metrics:
        value = con.execute(text(m["validation_query"])).scalar()
        print(f"  validation {m['name']}: {value}")
