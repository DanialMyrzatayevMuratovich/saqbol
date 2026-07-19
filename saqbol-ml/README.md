# saqbol-ml

Python ML service for SaqBol scam detection (KZ/RU). Serves the backend over **gRPC**
(`proto/ml/v1/ml.proto`) and exposes a **FastAPI REST** interface for manual testing.

Current model: hybrid **TF-IDF + Logistic Regression** baseline combined with KZ/RU
keyword rules for category and trigger explainability. The XLM-RoBERTa fine-tune path
lives in `training/train_transformer.py` (heavy deps in `requirements-transformer.txt`).

## Setup

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

bash scripts/gen_proto.sh          # generate gRPC stubs into app/generated
python training/train_baseline.py  # train baseline into models/
python -m app.server               # start gRPC (:9090) + FastAPI (:8000)
```

All ports and paths come from environment variables (`.env.example`), ready for Kubernetes.

## Interfaces

- gRPC `saqbol.ml.v1.ScamClassifier/Classify` and `/ClassifyStream` — consumed by saqbol-backend.
- REST:
  - `GET /health`
  - `GET /model`
  - `POST /classify` `{ "text": "...", "channel": "sms", "locale": "ru" }`

## Training the transformer

```bash
pip install -r requirements-transformer.txt
python training/train_transformer.py
```

Baseline vs transformer comparison (precision / recall / F1) feeds the thesis experiments.
