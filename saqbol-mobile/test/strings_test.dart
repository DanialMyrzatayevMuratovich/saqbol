import 'package:flutter_test/flutter_test.dart';
import 'package:saqbol_mobile/src/core/strings.dart';

void main() {
  test('russian and kazakh strings differ', () {
    const ru = AppStrings(AppLocale.ru);
    const kk = AppStrings(AppLocale.kk);

    expect(ru.login, 'Войти');
    expect(kk.login, 'Кіру');
    expect(ru.tabCall, isNot(equals(kk.tabCall)));
  });
}
