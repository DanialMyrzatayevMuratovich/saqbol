SAFE_ADVICE = "Сообщение выглядит безопасным, но всегда сверяйте отправителя."

CATEGORY_RULES = [
    {
        "name": "fake_bank",
        "advice": "Банк никогда не просит код из СМС. Не отвечайте, позвоните в банк сами по номеру с карты.",
        "triggers": [
            "код из смс", "код из sms", "смс код", "смс кодын", "одноразовый код",
            "карта заблокирована", "картаңыз бұғатталды", "служба безопасности",
            "қауіпсіздік қызметі", "продиктуйте код", "назовите код", "сообщите код",
            "отдел безопасности",
        ],
    },
    {
        "name": "phishing",
        "advice": "Не переходите по ссылке. Проверьте домен вручную, мошенники подделывают адреса банков.",
        "triggers": [
            "перейдите по ссылке", "войдите по ссылке", "kaspii.kz", "kaspi-kz",
            "egov-kz", "подтвердите данные", "обновите данные", "по ссылке",
        ],
    },
    {
        "name": "fake_prize",
        "advice": "Настоящие розыгрыши не требуют комиссию заранее. Не переводите деньги за «приз».",
        "triggers": [
            "вы выиграли", "поздравляем", "құттықтаймыз", "сыйлық", "ұтып алдыңыз",
            "приз", "компенсация", "оплатите комиссию", "переведите комиссию",
            "выплата", "победитель",
        ],
    },
    {
        "name": "fake_police",
        "advice": "Полиция и прокуратура не требуют переводить деньги на «безопасный счёт». Это мошенничество.",
        "triggers": [
            "полиция", "прокуратура", "следователь", "уголовное дело",
            "оформлен кредит", "безопасный счёт", "переведите деньги",
            "переведите средства", "переведите на безопасный",
        ],
    },
    {
        "name": "kaspi_scam",
        "advice": "Оплату и переводы делайте только в официальном приложении Kaspi, не по присланным ссылкам.",
        "triggers": [
            "kaspi.link", "каспи перевод", "перевод kaspi", "оплата kaspi",
            "оплатите через каспи", "подтвердите оплату",
        ],
    },
]


def match(text: str) -> tuple[str | None, list[str], str]:
    lowered = text.lower()
    best_name = None
    best_advice = SAFE_ADVICE
    best_triggers: list[str] = []

    for rule in CATEGORY_RULES:
        hits = [trigger for trigger in rule["triggers"] if trigger in lowered]
        if len(hits) > len(best_triggers):
            best_triggers = hits
            best_name = rule["name"]
            best_advice = rule["advice"]

    return best_name, best_triggers, best_advice


def score(match_count: int) -> float:
    if match_count == 0:
        return 0.05
    if match_count == 1:
        return 0.55
    if match_count == 2:
        return 0.82
    return 0.94
