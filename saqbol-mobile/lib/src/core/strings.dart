import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/guard/call_guard.dart';
import 'providers.dart';

enum AppLocale { ru, kk, en }

/// Maps a stored language code back to a locale, falling back to Russian for
/// anything unknown (including nothing stored yet).
AppLocale localeFromCode(String? code) =>
    AppLocale.values.asNameMap()[code] ?? AppLocale.ru;

class AppStrings {
  const AppStrings(this.locale);

  final AppLocale locale;

  String _t(String ru, String kk, String en) => switch (locale) {
        AppLocale.ru => ru,
        AppLocale.kk => kk,
        AppLocale.en => en,
      };

  String get tagline => _t(
        'Цифровой щит от мошенников',
        'Алаяқтарға қарсы цифрлық қалқан',
        'A digital shield against scammers',
      );
  String get login => _t('Войти', 'Кіру', 'Log in');
  String get register => _t('Зарегистрироваться', 'Тіркелу', 'Sign up');
  String get createAccount =>
      _t('Создать аккаунт', 'Аккаунт құру', 'Create an account');
  String get haveAccount => _t(
        'У меня есть аккаунт',
        'Менде аккаунт бар',
        'I already have an account',
      );
  String get phone => _t('Телефон', 'Телефон', 'Phone');
  String get password => _t('Пароль', 'Құпия сөз', 'Password');
  String get rememberMe => _t('Запомнить меня', 'Есте сақтау', 'Remember me');
  String get name => _t('Имя', 'Аты', 'Name');
  String get logout => _t('Выйти', 'Шығу', 'Log out');
  String get requestFailed => _t(
        'Не удалось выполнить запрос. Проверьте подключение.',
        'Сұрауды орындау мүмкін болмады. Байланысты тексеріңіз.',
        'Request failed. Check your connection.',
      );

  String get tabSms => _t('Проверка', 'Тексеру', 'Check');
  String get tabCall => _t('Звонок', 'Қоңырау', 'Call');
  String get tabHistory => _t('История', 'Тарих', 'History');

  String get smsTitle => _t('Проверка SMS', 'SMS тексеру', 'SMS check');
  String get smsHint => _t(
        'Вставьте или перешлите подозрительное SMS',
        'Күдікті SMS қойыңыз немесе жіберіңіз',
        'Paste or forward a suspicious SMS',
      );
  String get smsTextLabel =>
      _t('Текст сообщения', 'Хабарлама мәтіні', 'Message text');
  String get senderLabel => _t(
        'Отправитель (необязательно)',
        'Жіберуші (міндетті емес)',
        'Sender (optional)',
      );
  String get checkButton => _t('Проверить', 'Тексеру', 'Check');
  // Server errors by status code, so no English server text reaches the screen.
  String get invalidCredentials => _t(
        'Неверный телефон или пароль',
        'Телефон немесе құпия сөз қате',
        'Wrong phone or password',
      );
  String get phoneTaken => _t(
        'Этот номер уже зарегистрирован',
        'Бұл нөмір бұрын тіркелген',
        'This number is already registered',
      );
  String get checkLoginInput => _t(
        'Проверьте телефон и пароль: пароль не короче 6 символов',
        'Телефон мен құпия сөзді тексеріңіз: құпия сөз кемінде 6 таңба',
        'Check the phone and password: the password needs at least 6 characters',
      );
  String get tooManyRequests => _t(
        'Слишком много запросов. Подождите минуту.',
        'Сұраулар тым көп. Бір минут күтіңіз.',
        'Too many requests. Wait a minute.',
      );
  String get checkFailed => _t(
        'Проверка не удалась. Попробуйте ещё раз.',
        'Тексеру сәтсіз аяқталды. Қайталап көріңіз.',
        'Check failed. Please try again.',
      );

  String get tabGuard => _t('Защита', 'Қорғаныс', 'Guard');
  String get guardTitle => _t('Автозащита', 'Автоқорғаныс', 'Auto-protection');
  String get guardWatchTitle => _t(
        'Автопроверка новых SMS',
        'Жаңа SMS автотексеру',
        'Auto-check new SMS',
      );
  String get guardWatchSubtitle => _t(
        'Входящие сообщения проверяются в фоне',
        'Келген хабарламалар фонда тексеріледі',
        'Incoming messages are checked in the background',
      );
  String get guardCallTitle =>
      _t('Проверка звонков', 'Қоңырауларды тексеру', 'Call screening');
  String get guardCallSubtitle => _t(
        'Входящий номер сверяется с базой мошенников',
        'Кіріс нөмір алаяқтар базасымен салыстырылады',
        'Incoming numbers are checked against the scammer database',
      );
  String get guardScanButton =>
      _t('Просканировать все SMS', 'Барлық SMS сканерлеу', 'Scan all SMS');
  String get guardScanFailed => _t(
        'Сканирование не удалось',
        'Сканерлеу сәтсіз аяқталды',
        'Scan failed',
      );
  String get guardNothingFound => _t(
        'Опасных сообщений не найдено',
        'Қауіпті хабарлама табылмады',
        'No dangerous messages found',
      );
  String get guardPermissionTitle =>
      _t('Нужен доступ к SMS', 'SMS-ке рұқсат қажет', 'SMS access needed');
  String get guardPermissionBody => _t(
        'Чтобы автоматически выявлять мошенников, приложению нужен доступ к чтению SMS. Сообщения отправляются на сервер только для проверки.',
        'Алаяқтықты автоматты анықтау үшін қолданбаға SMS оқу рұқсаты керек. Хабарламалар тек тексеру үшін серверге жіберіледі.',
        'To detect scammers automatically, the app needs permission to read SMS. Messages are sent to the server only to be checked.',
      );
  String get guardPermissionGrant => _t('Разрешить', 'Рұқсат беру', 'Allow');
  String get guardPermissionSettings =>
      _t('Открыть настройки', 'Параметрлерді ашу', 'Open settings');
  String get guardChannelDescription => _t(
        'Оповещения о мошеннических сообщениях',
        'Алаяқтық хабарламалар туралы ескертулер',
        'Scam message alerts',
      );
  String scamSmsAlert(String sender) => sender.isEmpty
      ? _t('⚠️ Мошенническое SMS', '⚠️ Алаяқтық SMS', '⚠️ Scam SMS')
      : _t(
          '⚠️ Мошенническое SMS от $sender',
          '⚠️ Алаяқтық SMS: $sender',
          '⚠️ Scam SMS from $sender',
        );

  String get callTitle => _t('Звонок', 'Қоңырау', 'Call');
  String get startListening =>
      _t('Начать прослушивание', 'Тыңдауды бастау', 'Start listening');
  String get stopListening => _t('Остановить', 'Тоқтату', 'Stop');
  String get sessionInactive =>
      _t('Сессия не запущена', 'Сессия басталмаған', 'Session not started');
  String get sessionActive =>
      _t('Сессия активна', 'Сессия белсенді', 'Session active');
  String get listening => _t(
        'Слушаю разговор…',
        'Әңгімені тыңдап жатырмын…',
        'Listening to the conversation…',
      );
  String get noSession =>
      _t('Нет активной сессии', 'Белсенді сессия жоқ', 'No active session');
  String get callScamWarning => _t(
        'Возможно мошенник! Не диктуйте коды и не переводите деньги.',
        'Алаяқ болуы мүмкін! Кодтарды айтпаңыз және ақша аудармаңыз.',
        'Possible scammer! Do not share codes or transfer money.',
      );
  String get triggers => _t('Триггеры', 'Триггерлер', 'Triggers');
  String get transcript => _t('Транскрипт', 'Транскрипт', 'Transcript');
  String get manualFragment => _t(
        'Фрагмент вручную (демо)',
        'Үзіндіні қолмен енгізу (демо)',
        'Manual fragment (demo)',
      );

  String get historyEmpty => _t('История пуста', 'Тарих бос', 'No history yet');
  String historyLoadFailed(Object error) => _t(
        'Ошибка загрузки: $error',
        'Жүктеу қатесі: $error',
        'Failed to load: $error',
      );

  String get feedbackScam => _t('Это скам', 'Бұл алаяқтық', 'This is a scam');
  String get feedbackFalse =>
      _t('Ложная тревога', 'Жалған дабыл', 'False alarm');
  String get feedbackThanks => _t(
        'Спасибо, отзыв учтён',
        'Рақмет, пікір ескерілді',
        'Thanks, feedback recorded',
      );
  String get feedbackFailed => _t(
        'Не удалось отправить отзыв',
        'Пікірді жіберу мүмкін болмады',
        'Could not send feedback',
      );
  String modelVersion(String version) =>
      _t('Модель: $version', 'Модель: $version', 'Model: $version');

  String verdictLabel(String verdict) => switch (verdict) {
        'scam' => _t('Мошенничество', 'Алаяқтық', 'Scam'),
        'suspicious' => _t('Подозрительно', 'Күдікті', 'Suspicious'),
        _ => _t('Безопасно', 'Қауіпсіз', 'Safe'),
      };

  String categoryLabel(String category) => switch (category) {
        'fake_bank' => _t('Фейк-банк', 'Жалған банк', 'Fake bank'),
        'phishing' => _t('Фишинг', 'Фишинг', 'Phishing'),
        'fake_prize' => _t('Фейк-приз', 'Жалған ұтыс', 'Fake prize'),
        'fake_police' => _t('Фейк-полиция', 'Жалған полиция', 'Fake police'),
        'kaspi_scam' => _t('Kaspi-скам', 'Kaspi-алаяқтық', 'Kaspi scam'),
        'other' => _t('Другое', 'Басқа', 'Other'),
        _ => category,
      };

  /// Advice for a verdict in the interface language. The backend sends its own
  /// advice in Russian only, so that one is used just for categories this build
  /// does not know yet.
  String advice(String category, String fallback) => switch (category) {
        '' => _t(
            'Сообщение выглядит безопасным, но всегда сверяйте отправителя.',
            'Хабарлама қауіпсіз көрінеді, бірақ жіберушіні әрдайым тексеріңіз.',
            'The message looks safe, but always double-check the sender.',
          ),
        'fake_bank' => _t(
            'Банк никогда не просит код из СМС. Не отвечайте, позвоните в банк сами по номеру с карты.',
            'Банк ешқашан SMS кодын сұрамайды. Жауап бермеңіз, картадағы нөмір арқылы банкке өзіңіз қоңырау шалыңыз.',
            'A bank never asks for the code from an SMS. Do not reply — call the bank yourself using the number on your card.',
          ),
        'phishing' => _t(
            'Не переходите по ссылке. Проверьте домен вручную, мошенники подделывают адреса банков.',
            'Сілтемеге өтпеңіз. Доменді қолмен тексеріңіз — алаяқтар банк мекенжайларын қолдан жасайды.',
            'Do not follow the link. Check the domain yourself — scammers imitate bank addresses.',
          ),
        'fake_prize' => _t(
            'Настоящие розыгрыши не требуют комиссию заранее. Не переводите деньги за «приз».',
            'Шынайы ұтыс ойындары алдын ала комиссия талап етпейді. «Жүлде» үшін ақша аудармаңыз.',
            'Real giveaways never ask for a fee upfront. Do not send money for a “prize”.',
          ),
        'fake_police' => _t(
            'Полиция и прокуратура не требуют переводить деньги на «безопасный счёт». Это мошенничество.',
            'Полиция мен прокуратура ақшаны «қауіпсіз шотқа» аударуды талап етпейді. Бұл — алаяқтық.',
            'The police and prosecutors never ask you to move money to a “safe account”. This is a scam.',
          ),
        'kaspi_scam' => _t(
            'Оплату и переводы делайте только в официальном приложении Kaspi, не по присланным ссылкам.',
            'Төлем мен аударымды тек ресми Kaspi қосымшасында жасаңыз, жіберілген сілтемелер арқылы емес.',
            'Make payments and transfers only in the official Kaspi app, never through links sent to you.',
          ),
        'other' => _t(
            'Сообщение выглядит подозрительно. Не переходите по ссылкам, не сообщайте коды и не переводите деньги.',
            'Хабарлама күдікті көрінеді. Сілтемелерге өтпеңіз, кодтарды айтпаңыз және ақша аудармаңыз.',
            'This message looks suspicious. Do not follow links, share codes or send money.',
          ),
        _ => fallback,
      };
}

class LocaleController extends Notifier<AppLocale> {
  bool _selected = false;

  @override
  AppLocale build() {
    _restore();
    return AppLocale.ru;
  }

  Future<void> _restore() async {
    final code = await ref.read(localeStorageProvider).read();
    // A choice made while the read was in flight wins over the stored one.
    if (code != null && !_selected) state = localeFromCode(code);
  }

  Future<void> select(AppLocale locale) async {
    _selected = true;
    state = locale;
    await ref.read(localeStorageProvider).save(locale.name);
    await CallGuard.syncLocale(locale.name);
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, AppLocale>(LocaleController.new);

final stringsProvider = Provider<AppStrings>((ref) {
  return AppStrings(ref.watch(localeControllerProvider));
});
