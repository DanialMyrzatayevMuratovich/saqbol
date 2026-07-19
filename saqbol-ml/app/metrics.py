from prometheus_client import Counter, Histogram

classifications_total = Counter(
    "saqbol_ml_classifications_total",
    "Total classifications by verdict and channel.",
    ["verdict", "channel"],
)

classify_latency_seconds = Histogram(
    "saqbol_ml_classify_latency_seconds",
    "Classification latency in seconds.",
)


def observe(result, channel: str) -> None:
    classifications_total.labels(result.verdict, channel or "unknown").inc()
    classify_latency_seconds.observe(result.latency_ms / 1000)
