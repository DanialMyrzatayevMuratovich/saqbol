from fastapi import FastAPI, Response
from prometheus_client import CONTENT_TYPE_LATEST, generate_latest
from pydantic import BaseModel, ConfigDict, Field

from . import metrics
from .config import load_settings
from .factory import build_classifier


class ClassifyRequest(BaseModel):
    text: str = Field(min_length=1)
    channel: str = "sms"
    locale: str = ""


class ClassifyResponse(BaseModel):
    model_config = ConfigDict(protected_namespaces=())

    verdict: str
    probability: float
    category: str
    triggers: list[str]
    advice: str
    latency_ms: int
    model_version: str


settings = load_settings()
classifier = build_classifier(settings)

app = FastAPI(title="SaqBol ML Service", version="1.0.0")


@app.get("/health")
def health() -> dict:
    return {"status": "ok", "model_ready": classifier.model.ready, "model_version": settings.model_version}


@app.get("/model")
def model_info() -> dict:
    return {
        "model_version": settings.model_version,
        "model_ready": classifier.model.ready,
        "scam_threshold": settings.scam_threshold,
        "suspicious_threshold": settings.suspicious_threshold,
    }


@app.get("/metrics")
def prometheus_metrics() -> Response:
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.post("/classify", response_model=ClassifyResponse)
def classify(request: ClassifyRequest) -> ClassifyResponse:
    result = classifier.classify(request.text, request.channel, request.locale)
    metrics.observe(result, request.channel)
    return ClassifyResponse(
        verdict=result.verdict,
        probability=result.probability,
        category=result.category,
        triggers=result.triggers,
        advice=result.advice,
        latency_ms=result.latency_ms,
        model_version=result.model_version,
    )
