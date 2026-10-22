from app.classifier import BaselineModel, ScamClassifier, rules
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


def test_english_scam_from_rules_without_model():
    classifier = build_classifier()
    result = classifier.classify(
        "Bank security service: your card has been blocked, tell us the code from the SMS"
    )
    assert result.verdict == VERDICT_SCAM
    assert result.category == "fake_bank"
    assert result.triggers


def test_model_only_verdict_gets_other_category_and_a_warning():
    class AlwaysScam(BaselineModel):
        def predict_proba(self, text):
            return 0.95

        def explain(self, text, top_k=5):
            return []

    classifier = ScamClassifier(
        model=AlwaysScam(None),
        scam_threshold=0.8,
        suspicious_threshold=0.45,
        model_version="test",
    )
    result = classifier.classify("Text no rule knows about")
    assert result.verdict == VERDICT_SCAM
    assert result.category == "other"
    assert result.advice == rules.OTHER_ADVICE
