"""Mining task: classify users as insider / normal from gold.user_features (SQL -> Python -> SQL).

Baseline : logistic regression (scaled).      Improved : random forest.
Both are scored on the same stratified hold-out split. Results go back to SQL:
  ml.model_metrics     one row per run, model and metric
  ml.user_risk_score   one row per run, model and user (risk_score, predicted_label, data_split, run_id ...)

Leakage guard: a feature that is zero for every normal user but non-zero for insiders is excluded automatically
(e.g. http/email counts built only from insider ground-truth files). Use --keep-leaky to disable the guard.
Run:  python -m src.mining.baseline
"""
import datetime as dt
import sys
import uuid

import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import average_precision_score, f1_score, precision_score, recall_score, roc_auc_score
from sklearn.model_selection import train_test_split
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler

FEATURES = ["total_events", "logons", "after_hours_logons", "usb_connects", "http_events",
            "email_events", "distinct_pcs", "active_days", "O", "C", "E", "A", "N"]
LABEL = "is_insider"
VERSION = "v0.1"


def detect_leaky(df, features):
    """Features that are always 0 for normal users but positive for at least one insider."""
    normal, insider = df[df[LABEL] == 0], df[df[LABEL] == 1]
    return [f for f in features
            if (normal[f].fillna(0) == 0).all() and (insider[f].fillna(0) > 0).any()]


def make_models(seed=42):
    return {
        "logreg_baseline": make_pipeline(StandardScaler(), LogisticRegression(max_iter=1000, class_weight="balanced")),
        "random_forest": RandomForestClassifier(n_estimators=300, class_weight="balanced_subsample",
                                                random_state=seed, n_jobs=-1),
    }


def evaluate(df, features, seed=42, test_size=0.3):
    """Fit every model on the train split and score the hold-out split. Returns (metrics, scores)."""
    X = df[features].fillna(0).astype(float)
    y = df[LABEL].astype(int)
    X_tr, X_te, y_tr, y_te = train_test_split(X, y, test_size=test_size, stratify=y, random_state=seed)
    split = pd.Series("train", index=df.index)
    split.loc[X_te.index] = "test"
    metrics, scores = {}, {}
    for name, model in make_models(seed).items():
        model.fit(X_tr, y_tr)
        prob_te = model.predict_proba(X_te)[:, 1]
        pred_te = (prob_te >= 0.5).astype(int)
        metrics[name] = {
            "precision": precision_score(y_te, pred_te, zero_division=0),
            "recall": recall_score(y_te, pred_te, zero_division=0),
            "f1": f1_score(y_te, pred_te, zero_division=0),
            "roc_auc": roc_auc_score(y_te, prob_te),
            "pr_auc": average_precision_score(y_te, prob_te),
        }
        scores[name] = pd.DataFrame({"user_id": df["user_id"], "risk_score": model.predict_proba(X)[:, 1],
                                     "actual_label": y, "data_split": split})
        scores[name]["predicted_label"] = (scores[name]["risk_score"] >= 0.5).astype(int)
    return metrics, scores


def main():
    from src.db import get_engine
    engine = get_engine()
    df = pd.read_sql("SELECT * FROM gold.features_user_model", engine)
    if df[LABEL].sum() < 2:
        raise SystemExit("Need at least 2 insiders in gold.user_features to train.")
    features = list(FEATURES)
    if "--keep-leaky" not in sys.argv:
        leaky = detect_leaky(df, features)
        if leaky:
            print("WARNING: excluded as label leakage (zero for every normal user):", leaky)
            features = [f for f in features if f not in leaky]
    print(f"{len(df)} users, {int(df[LABEL].sum())} insiders, features: {features}")

    metrics, scores = evaluate(df, features)
    run_id, now = str(uuid.uuid4()), dt.datetime.now()
    rows, outputs = [], []
    for name, m in metrics.items():
        print(name, {k: round(v, 3) for k, v in m.items()})
        rows += [{"run_id": run_id, "model_name": name, "model_version": VERSION, "metric_name": k,
                  "metric_value": float(v), "generated_at": now} for k, v in m.items()]
        out = scores[name].assign(model_name=name, model_version=VERSION, run_id=run_id, generated_at=now)
        outputs.append(out)
    pd.DataFrame(rows).to_sql("model_metrics", engine, schema="ml", if_exists="append", index=False)
    pd.concat(outputs).to_sql("user_risk_score", engine, schema="ml", if_exists="append", index=False)
    print("Written to ml.model_metrics and ml.user_risk_score, run_id =", run_id)


if __name__ == "__main__":
    main()
