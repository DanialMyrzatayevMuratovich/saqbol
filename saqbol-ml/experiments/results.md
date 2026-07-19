# SaqBol — эксперименты по детекции скама (baseline)

Датасет (seed): 44 сообщений KZ/RU, 5-fold стратифицированная кросс-валидация.
Акцент на recall по классу «скам» (пропуск мошенничества критичнее ложной тревоги, NFR-2).

## Сравнение моделей

| Модель | Precision (scam) | Recall (scam) | F1 (scam) | ROC-AUC |
|---|---|---|---|---|
| TF-IDF + LogReg | 0.885 | 0.958 | 0.920 | 0.964 |
| TF-IDF + LinearSVM | 0.885 | 0.958 | 0.920 | 0.964 |
| TF-IDF + NaiveBayes | 0.727 | 1.000 | 0.842 | 0.963 |

## Confusion matrix — TF-IDF + NaiveBayes

| | предсказано safe | предсказано scam |
|---|---|---|
| **факт safe** | 11 | 9 |
| **факт scam** | 0 | 24 |

> Baseline. Сравнение с fine-tuned XLM-RoBERTa проводится после сбора полного корпуса (training/train_transformer.py).
