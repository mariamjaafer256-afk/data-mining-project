import numpy as np
import pandas as pd
from src.mining.baseline import FEATURES, LABEL, detect_leaky, evaluate


def synthetic(n=400, insiders=40, seed=0):
    rng = np.random.default_rng(seed)
    df = pd.DataFrame({f: rng.poisson(5, n).astype(float) for f in FEATURES})
    df["user_id"] = [f"U{i:04d}" for i in range(n)]
    df[LABEL] = 0
    df.loc[:insiders - 1, LABEL] = 1
    df.loc[df[LABEL] == 1, "usb_connects"] += 8          # a real signal
    return df


def test_evaluate_returns_metrics_and_one_score_per_user():
    df = synthetic()
    metrics, scores = evaluate(df, FEATURES)
    assert set(metrics) == {"logreg_baseline", "random_forest"}
    for name in metrics:
        assert 0.5 < metrics[name]["roc_auc"] <= 1.0
        assert len(scores[name]) == len(df) and scores[name]["user_id"].is_unique
        assert scores[name]["risk_score"].between(0, 1).all()
        assert set(scores[name]["data_split"]) == {"train", "test"}


def test_detect_leaky_flags_feature_that_is_zero_for_normal_users():
    df = synthetic()
    df["http_events"] = 0.0
    df.loc[df[LABEL] == 1, "http_events"] = 12.0
    assert detect_leaky(df, FEATURES) == ["http_events"]
