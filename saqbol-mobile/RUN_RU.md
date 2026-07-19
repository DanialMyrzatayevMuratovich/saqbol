# SaqBol Mobile — как запустить (Flutter)

Инструкция под текущее развёртывание. Общий ранбук лежит в `../CLAUDE.md`,
состояние сервера — в `../HANDOFF.md`.

## Главное, что отличается от README

1. **На этом сервере Flutter не установлен**, и сервер headless — эмулятора
   и графической среды нет. Мобильное приложение запускается **с твоей
   машины** (ноутбук/десктоп), а не здесь.
2. **Порт backend — 8082, не 8080.** В `README.md` и `lib/src/core/app_config.dart`
   (`defaultValue`) прописан `localhost:8080` — на этом сервере он занят чужим
   продакшн-сервисом. Если запустить без `--dart-define`, приложение молча
   пойдёт не туда.
3. **`10.0.2.2` здесь не подойдёт.** Этот адрес значит «хост, на котором крутится
   сам эмулятор». Backend работает на удалённом сервере, поэтому нужен его IP.

## Адрес backend

```
http://89.167.96.246:8082
```

Проверить доступность со своей машины перед запуском приложения:

```bash
curl http://89.167.96.246:8082/health     # ожидается {"status":"ok"}
```

Если не отвечает — читай раздел «Безопасность» ниже, возможно порт стоит
закрыть, а не открывать.

## Подготовка

Нужен Flutter 3.41+ (в `pubspec.yaml`: Dart SDK `^3.11.3`).

```bash
git clone https://github.com/DanialMyrzatayevMuratovich/saqbol.git
cd saqbol/saqbol-mobile
flutter pub get
flutter doctor          # убедиться, что тулчейн нужной платформы зелёный
flutter devices         # список подключённых устройств/эмуляторов
```

## Запуск

Адрес API передаётся через `--dart-define` при каждом запуске — в коде
хоста нет (`String.fromEnvironment('API_BASE_URL')` в `lib/src/core/app_config.dart`).

```bash
# Android-эмулятор или физический телефон (в одной сети / через интернет)
flutter run --dart-define=API_BASE_URL=http://89.167.96.246:8082

# iOS-симулятор
flutter run -d iphone --dart-define=API_BASE_URL=http://89.167.96.246:8082

# браузер (в проекте есть web/)
flutter run -d chrome --dart-define=API_BASE_URL=http://89.167.96.246:8082
```

Если backend запущен локально у тебя же, а не на сервере:
`--dart-define=API_BASE_URL=http://10.0.2.2:8082` для Android-эмулятора,
`http://localhost:8082` — для iOS-симулятора, web и десктопа.

## Сборка APK

```bash
flutter build apk --dart-define=API_BASE_URL=http://89.167.96.246:8082
# результат: build/app/outputs/flutter-apk/app-release.apk
```

Адрес вшивается в бинарник на этапе сборки — под другой сервер нужна
пересборка.

## Android Studio / VS Code

Открыть папку `saqbol-mobile/`, дождаться Gradle sync. `--dart-define`
задаётся в run configuration:

- **Android Studio:** Run → Edit Configurations → поле *Additional run args*:
  `--dart-define=API_BASE_URL=http://89.167.96.246:8082`
- **VS Code:** в `.vscode/launch.json` → `"args": ["--dart-define=API_BASE_URL=http://89.167.96.246:8082"]`

## Тесты

```bash
flutter test
```

## Платформенные тонкости

- **Android:** cleartext HTTP уже разрешён — в `AndroidManifest.xml` стоит
  `android:usesCleartextTraffic="true"`, разрешение `INTERNET` есть. Плоский
  `http://` работает без правок.
- **iOS:** исключений ATS в `ios/Runner/Info.plist` **нет**. iOS по умолчанию
  блокирует незашифрованный HTTP, поэтому на симуляторе/устройстве запросы
  к `http://89.167.96.246:8082` упадут. Нужен либо HTTPS на backend, либо
  ручное исключение ATS в `Info.plist` (правка не внесена — это ослабление
  безопасности приложения, делать осознанно).
- **Web:** браузер пойдёт с другого origin, поэтому нужен CORS на backend.
  Если словишь ошибку CORS — это настройка сервера, а не приложения.

## Что делает приложение

Регистрация/логин с хранением JWT в secure storage, автообновление токена
по 401 (Dio interceptor), ручная проверка SMS (`POST /sms/check`) с карточкой
вердикта и подсветкой триггерных фраз, история проверок (`GET /history`).
Тестовый пользователь на сервере: `+77000000001` / `secret123`.

## Безопасность — прочитай до того, как раздавать APK

JWT-секреты заменены на случайные (в `.env` на сервере) — подделать токен
больше нельзя. Но firewall выключен (`ufw inactive`, `iptables INPUT policy
ACCEPT`), backend опубликован на `0.0.0.0:8082` и работает **по HTTP без TLS**:
API открыт всему интернету, а пароли и токены идут открытым текстом.

Для реального использования нужен домен с TLS. Для приватного доступа —
закрыть порт на `127.0.0.1` и ходить через SSH-туннель:

```bash
ssh -L 8082:localhost:8082 root@89.167.96.246
# затем в приложении: API_BASE_URL=http://localhost:8082
```
