import 'package:flutter_test/flutter_test.dart';
import 'package:saqbol_mobile/src/core/strings.dart';

void main() {
  const ru = AppStrings(AppLocale.ru);
  const kk = AppStrings(AppLocale.kk);
  const en = AppStrings(AppLocale.en);

  test('russian, kazakh and english strings differ', () {
    expect(ru.login, 'Войти');
    expect(kk.login, 'Кіру');
    expect(en.login, 'Log in');
    expect(ru.tabCall, isNot(equals(kk.tabCall)));
    expect(en.tabCall, isNot(equals(ru.tabCall)));
  });

  test('verdicts and categories are labelled in the interface language', () {
    expect(ru.verdictLabel('scam'), 'Мошенничество');
    expect(kk.verdictLabel('scam'), 'Алаяқтық');
    expect(en.verdictLabel('scam'), 'Scam');
    expect(en.verdictLabel('anything else'), 'Safe');

    expect(en.categoryLabel('fake_bank'), 'Fake bank');
    expect(en.categoryLabel('not_a_category'), 'not_a_category');
  });

  test('advice is localised for known categories only', () {
    const fromBackend = 'Совет от сервера';

    expect(en.advice('phishing', fromBackend), startsWith('Do not follow'));
    expect(kk.advice('phishing', fromBackend), isNot(fromBackend));
    expect(en.advice('', fromBackend), contains('looks safe'));
    expect(en.advice('not_a_category', fromBackend), fromBackend);
  });

  test('english interface has no cyrillic left in it', () {
    final cyrillic = RegExp('[А-Яа-яЁёӘәҒғҚқҢңӨөҰұҮүҺһІі]');
    final samples = [
      en.tagline,
      en.register,
      en.requestFailed,
      en.smsHint,
      en.checkFailed,
      en.guardPermissionBody,
      en.guardChannelDescription,
      en.scamSmsAlert(''),
      en.scamSmsAlert('+77000000000'),
      en.callScamWarning,
      en.triggers,
      en.transcript,
      en.manualFragment,
      en.historyEmpty,
      en.historyLoadFailed('timeout'),
      en.feedbackFailed,
      en.modelVersion('v1'),
      for (final verdict in ['scam', 'suspicious', 'safe'])
        en.verdictLabel(verdict),
      for (final category in [
        '',
        'fake_bank',
        'phishing',
        'fake_prize',
        'fake_police',
        'kaspi_scam',
        'other',
      ]) ...[en.categoryLabel(category), en.advice(category, '')],
    ];

    for (final sample in samples) {
      expect(cyrillic.hasMatch(sample), isFalse, reason: sample);
    }
  });

  test('unknown or missing language code falls back to russian', () {
    expect(localeFromCode('en'), AppLocale.en);
    expect(localeFromCode('kk'), AppLocale.kk);
    expect(localeFromCode(null), AppLocale.ru);
    expect(localeFromCode('de'), AppLocale.ru);
  });
}
