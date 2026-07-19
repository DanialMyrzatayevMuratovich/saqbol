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
