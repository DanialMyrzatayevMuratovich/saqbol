# Prototype screenshots

Screenshots of the key scenarios in [08-prototype.md](../08-prototype.md) (task SAQ-35).
Use test accounts and sample messages only. No real phone numbers or personal SMS.

For every capture, record its source commit, device/emulator and whether input was typed or
recognised from speech. A Kazakh text verdict or a manually injected call fragment is not proof
of Kazakh speech recognition. A model screenshot labelled `real-only` refers to the legacy
source-selected course/seed cohort unless an authenticated received-SMS dataset is explicitly
documented; caption or recapture that label before using it as evaluation evidence. See the
[implementation/evidence record](../implementation-evidence.md).

| File | Scenario |
|---|---|
| `mobile-01-login.png` | S1 Login, language switch |
| `mobile-02-sms-scam-ru.png` | S2 Verdict card for a Russian fake-bank SMS, triggers highlighted |
| `mobile-03-sms-scam-kk.png` | S2 Verdict card for a Kazakh message |
| `mobile-04-sms-safe.png` | S2 Safe verdict |
| `mobile-05-guard.png` | S3 Protection screen with permissions and inbox-scan summary |
| `mobile-06-guard-notification.png` | S3 Notification for a scam SMS / high-risk call |
| `mobile-07-voice-alert.png` | S4 Live call analysis with the red alert |
| `mobile-08-history.png` | S5 History with feedback buttons |
| `web-01-dashboard.png` | W1 Dashboard |
| `web-02-messages.png` | W2 Flagged messages |
| `web-03-models.png` | W3 Model versions |
