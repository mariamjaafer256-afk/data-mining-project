from pathlib import Path
import yaml

REQUIRED = ["name", "label", "definition", "owner", "grain", "sql", "dimensions", "null_policy", "validation_query"]


def load():
    return yaml.safe_load(Path("semantic/metrics.yml").read_text(encoding="utf-8"))["metrics"]


def test_every_metric_has_all_required_keys():
    metrics = load()
    assert metrics, "metrics.yml has no metrics"
    for m in metrics:
        for key in REQUIRED:
            assert key in m, f"metric {m.get('name')} is missing '{key}'"


def test_metric_names_are_unique():
    names = [m["name"] for m in load()]
    assert len(names) == len(set(names))
