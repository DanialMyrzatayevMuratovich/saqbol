import os

import joblib
import numpy as np

STOPWORDS = {
    "из", "по", "на", "в", "и", "с", "для", "от", "до", "за", "у", "о", "а",
    "что", "как", "это", "не", "вы", "мы", "он", "но",
}


def _is_informative(token: str) -> bool:
    words = token.split()
    if len(words) == 1:
        return len(words[0]) >= 3 and words[0] not in STOPWORDS
    return any(word not in STOPWORDS for word in words)


class BaselineModel:
    def __init__(self, pipeline=None):
        self.pipeline = pipeline

    @property
    def ready(self) -> bool:
        return self.pipeline is not None

    @classmethod
    def load(cls, model_dir: str) -> "BaselineModel":
        path = os.path.join(model_dir, "baseline.joblib")
        if not os.path.exists(path):
            return cls(None)
        return cls(joblib.load(path))

    def predict_proba(self, text: str) -> float:
        if self.pipeline is None:
            return 0.0
        return float(self.pipeline.predict_proba([text])[0][1])

    def explain(self, text: str, top_k: int = 5) -> list[str]:
        if self.pipeline is None:
            return []

        vectorizer = self.pipeline.named_steps["tfidf"]
        classifier = self.pipeline.named_steps["clf"]

        features = vectorizer.transform([text])
        coefficients = classifier.coef_[0]
        contributions = features.multiply(coefficients).tocoo()

        names = vectorizer.get_feature_names_out()
        scored = [
            (names[col], value)
            for col, value in zip(contributions.col, contributions.data)
            if value > 0 and _is_informative(names[col])
        ]
        scored.sort(key=lambda item: item[1], reverse=True)
        return [name for name, _ in scored[:top_k]]
