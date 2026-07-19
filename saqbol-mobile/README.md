# saqbol_mobile

Flutter app for SaqBol — SMS scam checking with explainable verdicts (KZ/RU).
Stack: Flutter, Riverpod (state), Dio (HTTP), flutter_secure_storage (JWT).

## Run

The backend base URL is injected at build/run time (no hardcoded host):

```bash
# iOS simulator / macOS / web -> host localhost
flutter run --dart-define=API_BASE_URL=http://localhost:8080

# Android emulator -> host is reachable at 10.0.2.2
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Requires saqbol-backend running (and saqbol-ml behind it).

## Structure

```
lib/src/
  core/            app config, token storage, Dio + auth-refresh interceptor, providers
  features/
    auth/          login/register, AuthController (Riverpod Notifier)
    sms/           SMS check screen, VerdictCard, HighlightedMessage (trigger highlighting)
    history/       check history from GET /history
    home/          bottom navigation shell
  shared/          verdict styles (color/label per verdict, category labels)
```

## What it does (this stage)

- Register / login, tokens stored securely; Dio auto-refreshes on 401.
- Manual SMS check (`POST /sms/check`): paste/forward a message, optional sender.
- Verdict card: color-coded verdict, scam probability, category, advice, and the
  original text with trigger phrases highlighted (explainability, FR-3).
- History screen (`GET /history`).

## Next

- Android auto-read of incoming SMS via platform channel (Telephony) — Android only.
- iOS `ILMessageFilterExtension` for unknown senders.
- KZ/RU UI localization toggle (FR-18).
- Voice module (WebSocket `/ws/call`) — later roadmap stage.
