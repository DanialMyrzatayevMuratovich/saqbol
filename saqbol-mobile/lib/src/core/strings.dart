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
  String get senderLabel => _t(
        'Отправитель (необязательно)',
        'Жіберуші (міндетті емес)',
        'Sender (optional)',
      );
  String get checkButton => _t('Проверить', 'Тексеру', 'Check');
  String get checkFailed => _t(
        'Проверка не удалась. Попробуйте ещё раз.',
        'Тексеру сәтсіз аяқталды. Қайталап көріңіз.',
        'Check failed. Please try again.',
      );

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
  String get historyLoadFailed => _t(
        'Не удалось загрузить историю. Потяните вниз, чтобы обновить.',
        'Тарихты жүктеу мүмкін болмады. Жаңарту үшін төмен тартыңыз.',
        'Could not load the history. Pull down to refresh.',
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

  // --- Navigation -----------------------------------------------------------
  String get tabHome => _t('Главная', 'Басты', 'Home');
  String get tabSettings => _t('Настройки', 'Баптаулар', 'Settings');

  // --- Onboarding -----------------------------------------------------------
  String get onbTitle1 => _t(
        'Будьте на шаг впереди мошенников',
        'Алаяқтардан бір қадам алда болыңыз',
        'Stay one step ahead of scammers',
      );
  String get onbBody1 => _t(
        'SaqBol проверяет SMS и звонки на казахском и русском и объясняет, чем они опасны.',
        'SaqBol қазақ және орыс тіліндегі SMS пен қоңырауларды тексеріп, неліктен қауіпті екенін түсіндіреді.',
        'SaqBol checks SMS and calls in Kazakh and Russian and explains why they are dangerous.',
      );
  String get onbTitle2 => _t('Что умеет SaqBol', 'SaqBol не істей алады', 'What SaqBol does');
  String get onbFeature1Title => _t('Проверка SMS', 'SMS тексеру', 'SMS check');
  String get onbFeature1Body => _t(
        'Вставьте сообщение и увидите вердикт и опасные фразы',
        'Хабарламаны қойыңыз да, шешім мен қауіпті сөздерді көріңіз',
        'Paste a message to see the verdict and the risky phrases',
      );
  String get onbFeature2Title => _t('Защита в фоне', 'Фондағы қорғаныс', 'Background protection');
  String get onbFeature2Body => _t(
        'Новые SMS и звонки с опасных номеров проверяются автоматически',
        'Жаңа SMS пен қауіпті нөмірлерден келген қоңыраулар автоматты тексеріледі',
        'New SMS and calls from risky numbers are checked automatically',
      );
  String get onbFeature3Title => _t('Анализ звонка', 'Қоңырауды талдау', 'Call analysis');
  String get onbFeature3Body => _t(
        'Включите громкую связь, и SaqBol предупредит, если вас пытаются обмануть',
        'Динамикті қосыңыз, сізді алдауға тырысса, SaqBol ескертеді',
        'Put the call on speaker and SaqBol warns you if someone is trying to trick you',
      );
  String get onbTitle3 => _t('Ваши данные', 'Сіздің деректеріңіз', 'Your data');
  String get onbBody3 => _t(
        'Чтобы проверить сообщение, SaqBol отправляет его текст на сервер SaqBol и сохраняет в вашей истории. Звонок SaqBol не записывает: речь в текст переводит система телефона, на сервер уходит только текст. SaqBol не передаёт ваши данные третьим лицам.',
        'Хабарламаны тексеру үшін SaqBol оның мәтінін SaqBol серверіне жіберіп, тарихыңызда сақтайды. SaqBol қоңырауды жазбайды: сөзді мәтінге телефон жүйесі айналдырады, серверге тек мәтін жіберіледі. SaqBol деректеріңізді үшінші тұлғаларға бермейді.',
        'To check a message, SaqBol sends its text to the SaqBol server and keeps it in your history. SaqBol does not record calls: the phone turns speech into text and only the text is sent. SaqBol does not share your data with third parties.',
      );
  String get onbConsent => _t(
        'Я согласен(на) на отправку текста сообщений и расшифровки звонков на проверку',
        'Хабарламалар мәтіні мен қоңырау мәтінін тексеруге жіберуге келісемін',
        'I agree that message text and call transcripts are sent for checking',
      );
  String get onbNext => _t('Далее', 'Әрі қарай', 'Next');
  String get onbStart => _t('Начать', 'Бастау', 'Get started');
  String get onbSkip => _t('Пропустить', 'Өткізу', 'Skip');

  // --- Home -----------------------------------------------------------------
  String get protectedTitle => _t('Вы под защитой', 'Сіз қорғаудасыз', 'You are protected');
  String get protectedBody => _t(
        'Новые SMS и звонки проверяются в фоне',
        'Жаңа SMS пен қоңыраулар фонда тексеріледі',
        'New SMS and calls are checked in the background',
      );
  String get partialTitle => _t(
        'Защита включена частично',
        'Қорғаныс ішінара қосулы',
        'Protection is partly on',
      );
  String get partialBody => _t(
        'Включите все функции защиты в настройках',
        'Қорғаныстың барлық функциясын баптауларда қосыңыз',
        'Turn on all protection features in Settings',
      );
  String get offTitle => _t('Защита выключена', 'Қорғаныс өшірулі', 'Protection is off');
  String get offBody => _t(
        'Включите автопроверку SMS и проверку звонков',
        'SMS автотексеруін және қоңырау тексеруін қосыңыз',
        'Turn on automatic SMS and call checks',
      );
  String get turnOn => _t('Включить', 'Қосу', 'Turn on');
  String get statsTitle => _t('За 7 дней', 'Соңғы 7 күн', 'Last 7 days');
  String get statChecked => _t('Проверено', 'Тексерілді', 'Checked');
  String get checkMessageCta => _t('Проверить сообщение', 'Хабарламаны тексеру', 'Check a message');
  String get checkMessageCtaBody => _t(
        'Вставьте текст подозрительного SMS',
        'Күдікті SMS мәтінін қойыңыз',
        'Paste the text of a suspicious SMS',
      );
  String get recentThreats => _t('Последние угрозы', 'Соңғы қауіптер', 'Recent threats');
  String get noThreats => _t(
        'Опасных сообщений пока не было',
        'Әзірге қауіпті хабарлама болған жоқ',
        'No dangerous messages so far',
      );
  String get seeAll => _t('Все', 'Барлығы', 'See all');

  // --- Check ----------------------------------------------------------------
  String get checkIntro => _t(
        'Скопируйте подозрительное SMS и вставьте его сюда',
        'Күдікті SMS-ті көшіріп, осында қойыңыз',
        'Copy a suspicious SMS and paste it here',
      );
  String get paste => _t('Вставить', 'Қою', 'Paste');
  String get clear => _t('Очистить', 'Тазарту', 'Clear');
  String riskLabel(int percent) => _t(
        'Риск мошенничества: $percent%',
        'Алаяқтық қаупі: $percent%',
        'Scam risk: $percent%',
      );
  String get whyTitle => _t('Почему', 'Неліктен', 'Why');
  String get whatToDo => _t('Что делать', 'Не істеу керек', 'What to do');

  // --- Call -----------------------------------------------------------------
  String get callIntro => _t(
        'Включите громкую связь и нажмите кнопку. SaqBol будет слушать разговор и предупредит об обмане.',
        'Динамикті қосып, батырманы басыңыз. SaqBol әңгімені тыңдап, алаяқтық туралы ескертеді.',
        'Put the call on speaker and tap the button. SaqBol listens and warns you about a scam.',
      );
  String get alertTitle => _t('Возможно, это мошенник', 'Бұл алаяқ болуы мүмкін', 'This may be a scammer');
  String get alertReasons => _t('Что насторожило', 'Не күдік тудырды', 'What raised concern');
  String get endAnalysis => _t('Завершить анализ', 'Талдауды аяқтау', 'Stop analysis');
  String get notScammer => _t('Это не мошенник', 'Бұл алаяқ емес', 'Not a scammer');

  // --- History --------------------------------------------------------------
  String get filterAll => _t('Все', 'Барлығы', 'All');
  String get today => _t('Сегодня', 'Бүгін', 'Today');
  String get yesterday => _t('Вчера', 'Кеше', 'Yesterday');
  String get unknownSender => _t('Неизвестный отправитель', 'Белгісіз жіберуші', 'Unknown sender');
  String get nothingMatches => _t('Ничего не найдено', 'Ештеңе табылмады', 'Nothing found');

  // --- Settings -------------------------------------------------------------
  String get profileSubtitle => _t('Ваша цифровая защита', 'Сіздің цифрлық қорғанысыңыз', 'Your digital protection');
  String get sectionProtection => _t('Защита', 'Қорғаныс', 'Protection');
  String get sectionAppearance => _t('Внешний вид', 'Сыртқы түрі', 'Appearance');
  String get sectionPrivacy => _t('Конфиденциальность', 'Құпиялылық', 'Privacy');
  String get sectionAccount => _t('Аккаунт', 'Аккаунт', 'Account');
  String get themeLabel => _t('Тема', 'Тақырып', 'Theme');
  String get themeSystem => _t('Системная', 'Жүйелік', 'System');
  String get themeLight => _t('Светлая', 'Ашық', 'Light');
  String get themeDark => _t('Тёмная', 'Қараңғы', 'Dark');
  String get languageLabel => _t('Язык', 'Тіл', 'Language');
  String get enabled => _t('Включено', 'Қосулы', 'On');
  String get scanInboxSubtitle => _t(
        'Найти опасные сообщения среди уже полученных',
        'Бұрын келген хабарламалардан қауіптісін табу',
        'Find dangerous messages among the ones you already have',
      );
  String get privacyBody => _t(
        'Текст проверяемых сообщений и расшифровка разговора отправляются на сервер SaqBol и хранятся в вашей истории. Запись звонка SaqBol не делает: речь в текст переводит система телефона.',
        'Тексерілетін хабарламалар мәтіні мен сөйлесудің мәтіндік нұсқасы SaqBol серверіне жіберіліп, тарихыңызда сақталады. SaqBol қоңырауды жазбайды: сөзді мәтінге телефон жүйесі айналдырады.',
        'The text of checked messages and the call transcript are sent to the SaqBol server and kept in your history. SaqBol does not record calls: the phone itself turns speech into text.',
      );
  String get androidOnly => _t('Только на Android', 'Тек Android-та', 'Android only');
  String get toggleTheme => _t('Сменить тему', 'Тақырыпты ауыстыру', 'Switch theme');

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
