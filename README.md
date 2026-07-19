# SaqBol

**Saq bol (сақ бол — «будь начеку»)** — AI-платформа обнаружения мошеннических SMS и звонков
на казахском и русском языках: вердикт, категория схемы, подсветка триггеров и объяснение — до того,
как человек потеряет деньги.

## Архитектура

Клиенты ходят только в backend; backend вызывает ML-сервис по gRPC.

```
saqbol-mobile (Flutter)  ─┐
                          ├─HTTPS/WS─▶  saqbol-backend (Go)  ─gRPC─▶  saqbol-ml (Python)
saqbol-web (Next.js)     ─┘                   │                          TF-IDF+LogReg
                                              ▼                          (XLM-RoBERTa — next)
                                   PostgreSQL + Redis
```

| Проект | Стек | Назначение |
|---|---|---|
| **saqbol-backend** | Go, Gin, pgx, Redis, gRPC, JWT | REST + WebSocket API, бизнес-логика, репутация номеров |
| **saqbol-ml** | Python, FastAPI, gRPC, scikit-learn | классификатор скама (KZ/RU) + объяснимость |
| **saqbol-mobile** | Flutter, Riverpod, Dio | приложение: проверка SMS + real-time анализ звонка |
| **saqbol-web** | Next.js, Tailwind, Recharts | панель аналитики |

## Запуск всего стека одной командой

```bash
docker compose up --build
```

Поднимает Postgres, Redis, ML-сервис, backend и веб-панель.

- Backend API: http://localhost:8080 (`/health`, `/metrics`)
- Веб-панель: http://localhost:3000
- ML REST (отладка): http://localhost:8000

Postgres и Redis доступны только внутри сети compose. Мобильное приложение запускается отдельно
(`saqbol-mobile`) с `--dart-define=API_BASE_URL=...`.

## Отдельные проекты

Каждая папка содержит свой README с детальным запуском и структурой.

## Научная часть

`saqbol-ml/training/evaluate.py` считает метрики baseline-моделей (precision/recall/F1/ROC-AUC +
confusion matrix) и пишет отчёт в `saqbol-ml/experiments/`. Сравнение с fine-tuned XLM-RoBERTa —
после сбора полного корпуса (`training/train_transformer.py`).
