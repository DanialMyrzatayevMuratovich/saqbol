from app.classifier import BaselineModel, ScamClassifier
from app.classifier.base import VERDICT_SAFE, VERDICT_SCAM


def build_classifier():
    return ScamClassifier(
        model=BaselineModel(None),
        scam_threshold=0.8,
        suspicious_threshold=0.45,
        model_version="test",
    )


def test_scam_from_rules_without_model():
    classifier = build_classifier()
    result = classifier.classify(
        "Служба безопасности банка, ваша карта заблокирована, назовите код из смс"
    )
    assert result.verdict == VERDICT_SCAM
    assert result.category == "fake_bank"
    assert result.triggers


def test_safe_message():
    classifier = build_classifier()
    result = classifier.classify("Напоминание про встречу завтра в десять")
    assert result.verdict == VERDICT_SAFE
    assert result.category == ""
    assert result.triggers == []


def test_model_version_propagated():
    classifier = build_classifier()
    result = classifier.classify("любой текст")
    assert result.model_version == "test"
