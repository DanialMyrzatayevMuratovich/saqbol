import os
from dataclasses import dataclass


@dataclass
class Settings:
    http_port: int
    grpc_port: int
    model_dir: str
    model_version: str
    scam_threshold: float
    suspicious_threshold: float


def load_settings() -> Settings:
    return Settings(
        http_port=int(os.getenv("HTTP_PORT", "8000")),
        grpc_port=int(os.getenv("GRPC_PORT", "9090")),
        model_dir=os.getenv("MODEL_DIR", "models"),
        model_version=os.getenv("MODEL_VERSION", "baseline-tfidf-logreg-v1"),
        scam_threshold=float(os.getenv("SCAM_THRESHOLD", "0.8")),
        suspicious_threshold=float(os.getenv("SUSPICIOUS_THRESHOLD", "0.45")),
    )
