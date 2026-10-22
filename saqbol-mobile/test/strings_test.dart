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
      en.invalidCredentials,
      en.phoneTaken,
      en.checkLoginInput,
      en.tooManyRequests,
      en.guardPermissionBody,
      en.guardChannelDescription,
      en.scamSmsAlert(''),
      en.scamSmsAlert('+77000000000'),
      en.callScamWarning,
      en.triggers,
      en.transcript,
      en.manualFragment,
      en.historyEmpty,
      en.historyLoadFailed,
      en.feedbackFailed,
      en.modelVersion('v1'),
      en.onbBody1,
      en.onbFeature1Body,
      en.onbFeature2Body,
      en.onbFeature3Body,
      en.onbBody3,
      en.onbConsent,
      en.protectedBody,
      en.partialBody,
      en.offBody,
      en.checkMessageCtaBody,
      en.noThreats,
      en.checkIntro,
      en.riskLabel(39),
      en.callIntro,
      en.alertTitle,
      en.alertReasons,
      en.notScammer,
      en.unknownSender,
      en.nothingMatches,
      en.profileSubtitle,
      en.scanInboxSubtitle,
      en.privacyBody,
      en.androidOnly,
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

  test('onboarding does not promise kazakh speech recognition on calls', () {
    expect(ru.onbBody1, contains('только на русском'));
    expect(ru.onbBody1, contains('казахская речь ещё не поддерживается'));
    expect(kk.onbBody1, contains('тек орыс тілінде'));
    expect(kk.onbBody1, contains('қазақша сөйлеуді тану әлі жоқ'));
    expect(en.onbBody1, contains('Kazakh speech recognition is not available yet'));
    expect(en.onbBody1, isNot(contains('calls in Kazakh')));
  });

  test('privacy text separates server storage from what the history shows', () {
    expect(ru.privacyBody, contains('хранится на сервере, но в истории пока не показывается'));
    expect(kk.privacyBody, contains('серверде сақталады, бірақ тарихта әзірге көрсетілмейді'));
    expect(en.privacyBody, contains('stored on the server too, but are not shown in the history yet'));
    // The consent page says the call text is stored as well.
    expect(en.onbBody3, contains('stored there'));
  });

  test('risk is labelled as a risk, not as a confidence in the verdict', () {
    expect(en.riskLabel(39), contains('39%'));
    expect(en.riskLabel(39).toLowerCase(), contains('risk'));
    expect(ru.riskLabel(39), contains('39%'));
    expect(kk.riskLabel(39), contains('39%'));
  });

  test('unknown or missing language code falls back to russian', () {
    expect(localeFromCode('en'), AppLocale.en);
    expect(localeFromCode('kk'), AppLocale.kk);
    expect(localeFromCode(null), AppLocale.ru);
    expect(localeFromCode('de'), AppLocale.ru);
  });
}
