from dataclasses import dataclass, field


VERDICT_SAFE = "safe"
VERDICT_SUSPICIOUS = "suspicious"
VERDICT_SCAM = "scam"

CHANNEL_SMS = "sms"
CHANNEL_CALL = "call"


@dataclass
class ClassificationResult:
    verdict: str
    probability: float
    category: str
    triggers: list[str] = field(default_factory=list)
    advice: str = ""
    latency_ms: int = 0
    model_version: str = ""
