from app.classifier import rules


def test_matches_fake_bank():
    category, triggers, advice = rules.match(
        "Служба безопасности банка, назовите код из смс"
    )
    assert category == "fake_bank"
    assert triggers
    assert advice != rules.SAFE_ADVICE


def test_safe_message_has_no_category():
    category, triggers, advice = rules.match("Привет, увидимся завтра на обеде")
    assert category is None
    assert triggers == []
    assert advice == rules.SAFE_ADVICE


def test_score_grows_with_matches():
    assert rules.score(0) < rules.score(1) < rules.score(2) <= rules.score(3)


def test_matches_fake_bank_in_english():
    category, triggers, advice = rules.match(
        "Bank security service: your card has been blocked, tell us the code from the SMS"
    )
    assert category == "fake_bank"
    assert len(triggers) >= 2
    assert advice != rules.SAFE_ADVICE


def test_matches_each_category_in_english():
    samples = {
        "phishing": "Your account will be deleted. Follow the link and confirm your details",
        "fake_prize": "Congratulations! You have won, pay the fee to claim your prize",
        "fake_police": "Police: a criminal case has been opened, transfer the money to a safe account",
        "kaspi_scam": "I have paid, please confirm the payment: kaspi.link/pay",
    }
    for expected, text in samples.items():
        category, triggers, _ = rules.match(text)
        assert category == expected, text
        assert triggers


def test_safe_english_message_has_no_category():
    category, triggers, advice = rules.match("Hey, are we still meeting for lunch tomorrow?")
    assert category is None
    assert triggers == []
    assert advice == rules.SAFE_ADVICE


def test_prize_inside_a_domain_is_not_a_prize_scam():
    category, triggers, _ = rules.match("Ваш заказ ждёт выдачи: wb-kz-prize.shop")
    assert category is None
    assert triggers == []
