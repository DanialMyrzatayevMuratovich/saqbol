import time

from .base import (
    CHANNEL_SMS,
    VERDICT_SAFE,
    VERDICT_SCAM,
    VERDICT_SUSPICIOUS,
    ClassificationResult,
)
from . import rules
from .baseline import BaselineModel


class ScamClassifier:
    def __init__(
        self,
        model: BaselineModel,
        scam_threshold: float,
        suspicious_threshold: float,
        model_version: str,
    ):
        self.model = model
        self.scam_threshold = scam_threshold
        self.suspicious_threshold = suspicious_threshold
        self.model_version = model_version

    def classify(self, text: str, channel: str = CHANNEL_SMS, locale: str = "") -> ClassificationResult:
        start = time.perf_counter()

        model_probability = self.model.predict_proba(text)
        category, rule_triggers, advice = rules.match(text)
        rule_probability = rules.score(len(rule_triggers))
        probability = max(model_probability, rule_probability)

        verdict = VERDICT_SAFE
        if probability >= self.scam_threshold:
            verdict = VERDICT_SCAM
        elif probability >= self.suspicious_threshold:
            verdict = VERDICT_SUSPICIOUS

        if verdict == VERDICT_SAFE:
            return ClassificationResult(
                verdict=verdict,
                probability=round(probability, 4),
                category="",
                triggers=[],
                advice=rules.SAFE_ADVICE,
                latency_ms=int((time.perf_counter() - start) * 1000),
                model_version=self.model_version,
            )

        triggers = list(dict.fromkeys(rule_triggers + self.model.explain(text)))
        if category is None:
            category = "other"

        return ClassificationResult(
            verdict=verdict,
            probability=round(probability, 4),
            category=category,
            triggers=triggers[:8],
            advice=advice,
            latency_ms=int((time.perf_counter() - start) * 1000),
            model_version=self.model_version,
        )
