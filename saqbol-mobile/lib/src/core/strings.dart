import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLocale { ru, kk }

class AppStrings {
  const AppStrings(this.locale);

  final AppLocale locale;

  bool get _kk => locale == AppLocale.kk;

  String get tagline => _kk ? 'Алаяқтарға қарсы цифрлық қалқан' : 'Цифровой щит от мошенников';
  String get login => _kk ? 'Кіру' : 'Войти';
  String get register => _kk ? 'Тіркелу' : 'Зарегистрироваться';
  String get createAccount => _kk ? 'Аккаунт құру' : 'Создать аккаунт';
  String get haveAccount => _kk ? 'Менде аккаунт бар' : 'У меня есть аккаунт';
  String get phone => _kk ? 'Телефон' : 'Телефон';
  String get password => _kk ? 'Құпия сөз' : 'Пароль';
  String get name => _kk ? 'Аты' : 'Имя';
  String get logout => _kk ? 'Шығу' : 'Выйти';

  String get tabSms => _kk ? 'Тексеру' : 'Проверка';
  String get tabCall => _kk ? 'Қоңырау' : 'Звонок';
  String get tabHistory => _kk ? 'Тарих' : 'История';

  String get smsTitle => _kk ? 'SMS тексеру' : 'Проверка SMS';
  String get smsHint => _kk ? 'Күдікті SMS қойыңыз немесе жіберіңіз' : 'Вставьте или перешлите подозрительное SMS';
  String get smsTextLabel => _kk ? 'Хабарлама мәтіні' : 'Текст сообщения';
  String get senderLabel => _kk ? 'Жіберуші (міндетті емес)' : 'Отправитель (необязательно)';
  String get checkButton => _kk ? 'Тексеру' : 'Проверить';

  String get callTitle => _kk ? 'Қоңырау' : 'Звонок';
  String get startListening => _kk ? 'Тыңдауды бастау' : 'Начать прослушивание';
  String get stopListening => _kk ? 'Тоқтату' : 'Остановить';
  String get sessionInactive => _kk ? 'Сессия басталмаған' : 'Сессия не запущена';
  String get sessionActive => _kk ? 'Сессия белсенді' : 'Сессия активна';
  String get listening => _kk ? 'Әңгімені тыңдап жатырмын…' : 'Слушаю разговор…';

  String get feedbackScam => _kk ? 'Бұл алаяқтық' : 'Это скам';
  String get feedbackFalse => _kk ? 'Жалған дабыл' : 'Ложная тревога';
  String get feedbackThanks => _kk ? 'Рақмет, пікір ескерілді' : 'Спасибо, отзыв учтён';
}

class LocaleController extends Notifier<AppLocale> {
  @override
  AppLocale build() => AppLocale.ru;

  void toggle() {
    state = state == AppLocale.ru ? AppLocale.kk : AppLocale.ru;
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, AppLocale>(LocaleController.new);

final stringsProvider = Provider<AppStrings>((ref) {
  return AppStrings(ref.watch(localeControllerProvider));
});
