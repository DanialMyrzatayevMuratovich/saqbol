# 4. Existing System Comparison

All sources were accessed on **2026-10-22**. Where a fact comes from a vendor's own marketing,
it is marked *(vendor claim)*. Each cell is backed by the evidence list in §4.3. "?" means no
evidence was found either way; it is not a "no".

## 4.1 Systems compared

| System | Type | Why it is relevant |
|---|---|---|
| **Google Scam Detection** (Google Messages, Phone by Google) | On-device AI in Android | The closest technical analogue: content-based SMS detection and real-time call analysis |
| **Truecaller** | Caller ID + spam app | Market leader in caller ID; available in Kazakhstan; has AI SMS fraud protection in some markets |
| **Kaspersky Who Calls** | Caller ID + spam app | Officially available in Kazakhstan; Russian UI; community spam database |
| **Trend Micro ScamCheck** | Scam-check app | Explains *why* something is risky; on-demand AI text analysis |
| **Kazakh mobile operators' antifraud** (Beeline KZ, Kcell) | Network-level filtering | What Kazakhstan subscribers already have by default |

Also reviewed, outside the main table: the **National Bank of Kazakhstan Antifraud Centre**
(transaction-level, no consumer interface), **Hiya** (call screening limited to the US and Canada)
and **Apate.ai** (B2B only, no consumer app).

## 4.2 Comparison

✅ supported · ⚠️ partial / limited · ❌ not supported · ? no evidence found

| # | Criterion | Google Scam Detection | Truecaller | Kaspersky Who Calls | Trend Micro ScamCheck | KZ operator antifraud | **SaqBol (target)** |
|---|---|---|---|---|---|---|---|
| C1 | Analyses **Kazakh** text / speech | ❌ | ❌ | ❌ | ❌ | n/a (no content analysis) | ✅ |
| C2 | Analyses **Russian** text / speech | ❌ | ? (Russian UI only) | ❌ (Russian UI only) | ❌ | n/a | ✅ |
| C3 | Analyses **SMS content** | ✅ | ⚠️ India, Android only | ⚠️ links only, Premium | ✅ | ⚠️ behavioural, not content | ✅ |
| C4 | Analyses **call content in real time** | ⚠️ Pixel only, listed countries | ⚠️ synthetic-voice detection, US only | ❌ | ⚠️ video calls only | ❌ | ⚠️ speakerphone + OS STT; current Russian locale, Kazakh speech pending |
| C5 | **Number reputation** | ⚠️ | ✅ large database *(vendor claim)* | ✅ community labels | ⚠️ US, CA, JP, IT, TW only | ✅ network-level blocking | ⚠️ crowd-sourced from own users, small base |
| C6 | **Explains** the warning to the user | ⚠️ "Likely scam" label | ⚠️ spam-report statistics | ⚠️ category / organisation label | ✅ "see why something is risky" | ❌ silent blocking | ✅ trigger phrases + category + advice |
| C7 | **Platforms** | ⚠️ Android; calls on Pixel only | ✅ Android, iOS | ✅ Android, iOS | ✅ Android 15+, iOS 17+ | ✅ any phone | ⚠️ Android full; iOS manual check + live call |
| C8 | **Privacy** of message / call content | ✅ on-device (opt-in cloud mode) | ⚠️ on-device for SMS *(vendor claim)*; asks for contacts | ⚠️ | ? | ❌ operator-side | ⚠️ text sent to SaqBol server; OS recogniser may process audio remotely |
| C9 | **Available in Kazakhstan** | ❌ not in country lists | ✅ | ✅ | ❌ (not in KZ App Store) | ✅ by default | ✅ (prototype) |
| C10 | **Price for the user** | ? | Freemium, Premium 599 ₸ / month | Freemium, Premium 599 ₸ / month | $1.99–6.99 / month | Included | Free |
| C11 | Aware of **Kazakhstan-specific schemes** | ? | ? | ⚠️ published KZ data (2022) | ? | ✅ | ✅ categories built for local schemes |

### What the comparison shows

1. **No consumer product found analyses SMS text in Kazakh or Russian.** Google's and
   Trend Micro's language lists exclude both. Truecaller's text-based SMS filter is documented
   only for India. Who Calls checks only links. Operators filter by behaviour and connection
   parameters, not content.
2. **Real-time call-content analysis is not available in Kazakhstan.** Google's version is
   Pixel-only, and Kazakhstan is not among its supported countries. Hiya's equivalent is limited
   to the US and Canada. The tools that do work in Kazakhstan rely on number reputation.
3. **Warnings rarely explain themselves.** Only Trend Micro shows why something is risky, and
   it is not available in Kazakh, in Russian or in Kazakhstan. Local network-level protection
   blocks silently; Kcell is only "considering" notifying subscribers.
4. **Number reputation is the incumbents' strength and SaqBol's weakness.** Truecaller, Who Calls
   and the operators have large databases. SaqBol's reputation starts empty, so it is a
   supporting signal; content analysis is the main one.
5. **Operators cannot see messenger traffic** (Beeline's own statement). An app that analyses
   what the user pastes or hears is complementary to network-level protection, not a replacement.

**Positioning:** SaqBol does not compete with operator blocking or caller-ID databases. It
covers the gap they leave: understanding the *content* of a message or conversation in Kazakh
and Russian, and explaining the danger to the user before they act.

## 4.3 Evidence

### Google Scam Detection

- Detection "when the on-device AI detects a suspicious pattern in SMS, MMS, and RCS messages".
  It is on by default and applies only to non-contacts. Calls: "analyze conversations in
  real-time and warn users of potential scams", off by default.
  Launch was "in English first in the U.S., U.K. and Canada."
  — Google blog, 2025-03-04, https://blog.google/security/new-ai-powered-scam-detection-features/
- "Scam Detection only works on Google Pixel devices". Calls need a SIM from one of: US,
  Australia, Canada, France, Germany, India, Ireland, Italy, Japan, Mexico, Singapore, Spain, UK.
  "Data processing for Scam Detection is all done on-device."
  — https://support.google.com/phoneapp/answer/15654065?hl=en
- Languages added in September 2026: Arabic, French, German, Portuguese, Japanese, Spanish.
  — FoneArena, 2026-09-16, https://www.fonearena.com/blog/?p=492398 ; the help page lists 8
  languages (Arabic, English, French, German, Indonesian, Japanese, Portuguese, Spanish) —
  https://android.gadgethacks.com/news/september-pixel-drop-scam-detection-features-explained/
- Opt-in cloud analysis "in the encrypted Private AI Compute environment", disabled by default;
  bank-call verification with named banks (Banco do Brasil, Itaú Unibanco, Revolut).
  — BleepingComputer, 2026-10-15, https://www.bleepingcomputer.com/news/security/android-gets-ai-defenses-against-messaging-scams-fake-calls/

### Truecaller

- Kazakhstan App Store: Premium 599 ₸ / month, 4,100 ₸ / year; 30 UI languages including
  Russian, not Kazakh. "Automatically identify spam, fraudulent, scam and robocalls before you answer."
  — https://apps.apple.com/kz/app/truecaller-spam-call-blocker/id448142450
- AI SMS Fraud Protection "smartly detects fraudulent senders and messages". It is free in India
  on Android, and "processing is done locally on device" *(vendor claim)*.
  — FoneArena, 2023-04-17, https://www.fonearena.com/blog/391151/truecaller-ai-powered-sms-fraud-protection.html
- AI Call Scanner distinguishes human from AI-generated voices; "only available in the United
  States on Android devices".
  — SpeechTech, 2024-05-31, https://www.speechtechmag.com/Articles/News/Speech-Technology-News/TrueCaller-Launches-AI-Call-Scanner-164270.aspx
- Spammer profile shows the number of spam reports and calling activity.
  — https://pocketnow.com/truecaller-adds-spam-statistics-on-its-android-app
- "Truecaller – база более 3 млрд записей"; some services request access to contacts and the call log.
  — Digitalbusiness.kz, 2026-05-19, https://digitalbusiness.kz/2026-05-19/zvonyat-s-neznakomogo-nomera-v-kazahstane-kak-uznat-kto-eto-i-ne-popastsya-moshennikam/

### Kaspersky Who Calls

- "Available only in Russia, Indonesia, and in the Republic of Kazakhstan."
  — https://support.kaspersky.com/kaspersky-for-android/11.110/247343
- Kazakhstan App Store: free; Premium 599 ₸ / month, 5,990 ₸ / year; UI languages include Russian,
  not Kazakh. — https://apps.apple.com/kz/app/id1144206312
- Online databases of numbers "reported by users as spam"; "Spam labels are based on community
  feedback only." — https://support.kaspersky.com/whocalls-for-android/1.56/180507
- SMS: notifies if a message "contains links to malicious, spoofed, or advertising websites"
  (Premium). — https://support.kaspersky.com/whocalls-for-android/1.54/203364
- Shows organisation name, category, and whether the caller is "considered a spammer".
  — https://support.kaspersky.com/kaspersky-for-windows/21.18/240755
- Kazakhstan data: ~63% of users got spam calls in November 2022; schemes named are fake police,
  fake bank staff and classified-ad fraud. — Bizmedia.kz, 2022-12-06, https://bizmedia.kz/2022-12-06-tret-polzovatelej-1-raz-telefonnym-moshenn/md/

### Trend Micro ScamCheck

- "Automatically block spam and scam texts"; AI analysis of "phone numbers, websites, emails,
  text messages"; call block and caller ID "available in the US, Canada, Japan, Italy, and
  Taiwan"; UI languages English, French, German, Japanese, Traditional Chinese; $1.99–6.99 per month.
  — https://apps.apple.com/us/app/id1566099565
- "See why something is risky and get practical guidance on what to do next"; AI Video Scan for
  face-swap scams in video calls; Android 15+ and iOS 17+.
  — https://trendlife.com/en-us/products/scam-check
- The same app ID returns 404 in the Kazakhstan App Store (indirect evidence of non-availability;
  Google Play not checked). — https://apps.apple.com/kz/app/id1566099565

### Kazakh mobile operators

- Beeline: spoofed calls rejected "если инициирующий оператор не подтверждает запрос" (if the
  originating operator does not confirm the request); systems "анализируют данные, поведение,
  выявляют аномалии" (analyse data and behaviour, detect anomalies); 29 million attempts stopped
  in three years. Protection is on by default. Operators cannot monitor WhatsApp or Telegram.
  — Tengrinews, 2026-01-23, https://tengrinews.kz/article/beeline-zaschischaet-kazahstantsev-moshennikov-29-millionov-3724/
- Kcell: ~2.8 million suspicious calls blocked in 2024; notifications to subscribers about
  blocked calls only "рассматривается" (under consideration).
  — Tengrinews, 2025-04-21, https://tengrinews.kz/healthy/zablokirovali-28-milliona-podozritelnyih-vyizovov-568310/
- All operators: "свыше 77 миллионов мошеннических звонков" blocked (over 77 million fraudulent
  calls); detection by "поведенческие аномалии и технические параметры соединений" (behavioural
  anomalies and technical connection parameters).
  — Digitalbusiness.kz, 2026-01-26, https://digitalbusiness.kz/2026-01-26/kazahstantsam-rasskazali-kak-perehvativayut-zvonki-ot-moshennikov/amp/

### Also reviewed

- **National Bank Antifraud Centre:** started in July 2024 with more than 250 participants
  (banks, MFOs, law enforcement, operators). It has handled more than 80,000 incidents and keeps
  black and grey lists of accounts. There is no consumer app and no content analysis.
  — Zakon.kz, 2026-02-03, https://www.zakon.kz/mnenie/6506585-antifrodtsentr-pomog-sokhranit-19-mlrd-tenge-kazakhstantsam.html
- **Hiya:** listed in the Kazakhstan App Store, but "Call Screener, AI Voice Detection, and Call
  Safety Alerts" work only in the US and Canada, in English, French and Spanish.
  — https://apps.apple.com/kz/app/id986999874
- **Apate.ai:** "No, we don't offer a mobile app"; B2B conversational bots for telcos and banks
  in Australia. — https://www.apate.ai/ ; CommBank, 2025-06-27, https://www.commbank.com.au/articles/newsroom/2025/06/apate-ai.html

## 4.4 Limitations of this comparison

- Vendor documentation describes features, not detection quality. A hands-on test of the apps
  available in Kazakhstan (Truecaller, Who Calls) with real Kazakh and Russian scam SMS is planned
  (task SAQ-15) to replace some ⚠️ and ? cells with our own observations.
- Google Messages' own help page could not be opened (HTTP 403), so Google's language list comes
  from two secondary sources, which disagree on Indonesian and on Spain.
- Trend Micro's absence from Kazakhstan is inferred from the App Store only.
