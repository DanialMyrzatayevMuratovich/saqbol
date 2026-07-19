from .classifier import BaselineModel, ScamClassifier
from .config import Settings


def build_classifier(settings: Settings) -> ScamClassifier:
    model = BaselineModel.load(settings.model_dir)
    return ScamClassifier(
        model=model,
        scam_threshold=settings.scam_threshold,
        suspicious_threshold=settings.suspicious_threshold,
        model_version=settings.model_version,
    )
