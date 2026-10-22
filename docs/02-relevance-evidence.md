# 2. Evidence of Relevance

This page collects what we know about the problem and how we know it. It has three kinds of
evidence: published statistics (secondary data), our own analysis of available data, and
interviews with potential users (primary data). The last section separates **verified findings**
from **assumptions** that still need checking.

## 2.1 Published statistics for Kazakhstan

All sources were accessed on 2026-10-22. Figures are quoted as each source states them. Several
sources count differently, so the figures are not added up or compared directly.

| # | Finding | Period | Source |
|---|---|---|---|
| S1 | 28.9 thousand internet-fraud cases, a record; 23.3% of **all** registered crimes; 60.8% of all fraud; more than 55-fold growth since 2018 (517 cases) | 2025 | Finprom.kz in Kapital.kz, 2026-08-21 — https://kapital.kz/gosudarstvo/151957/kazhdoe-pyatoe-prestuplenie-v-kazahstane-internet-moshennichestvo.html |
| S2 | Damage from internet fraud: 12.2 bn tenge, of which 5 bn returned; Q1 2026: 4.8 bn tenge | 2025, Q1 2026 | Deputy chairman of the Committee on Legal Statistics (КПСиСУ), General Prosecutor's Office, in BES.media, 2026-04-08 — https://bes.media/news/zhertvam-internet-moshennichestva-vernuli-5-mlrd-tenge-za-2025-god-29b6f5/ |
| S3 | "Вишинг… и ложные SMS от имени банков или правоохранителей" (vishing and fake SMS in the name of banks or police): 6.2 thousand cases = 23.5% of internet fraud; 96.7% of the damage borne by individuals; only 20.7% of people who encounter fraudsters report it to the police | Jan–Nov 2025 | КПСиСУ via Finprom.kz, in Informburo, 2025-12-31 — https://informburo.kz/novosti/rekordnoe-kolicestvo-skolko-slucaev-mosennicestva-v-seti-zaregistrirovali-v-kazaxstane-v-2025-godu |
| S4 | Top scheme: "звонки и сообщения от имени банков – 2,9 тыс." (calls and messages in the name of banks — 2.9 thousand) out of 13.1 thousand internet-fraud cases; then phishing 2.7k, service ads 2.6k | Jan–Jul 2026 | Finprom.kz in Finratings.kz, 2026-08-21 — https://finratings.kz/news/16243-moshenniki-chashche-vsego-zvoniat-kazakhstantsam-ot-imeni-bankov/ |
| S5 | 17,909 fraud victims, "среди них 1131 пенсионеров" (1,131 of them pensioners); calls from "bank employees": 2,118 cases | Jan–May 2025 | General Prosecutor's Office, in 24.kz, 2025-06-16 — https://24.kz/ru/news/polezno-znat/715412-moshennichestvo-v-kazakhstane-kak-ne-stat-zhertvoj-i-chto-delat |
| S6 | "В основном попадает молодёжь и пенсионеры" (mostly young people and pensioners fall victim) | 2023 | Head of cybercrime unit, Ministry of Internal Affairs, in 24.kz, 2024-01-11 — https://24.kz/ru/news/social/634396-kakie-oblasti-kazakhstana-chashche-vsego-stanovyatsya-zhertvami-moshennikov |
| S7 | 77% of respondents had encountered phone fraudsters; "чаще всего мошенники говорят, что звонят из банка" (fraudsters most often say they are calling from the bank); 12% lost money | Jan–Mar 2023 | Aquarelle Research survey, in BES.media, 2023-05-24 — https://bes.media/news/rezultaty-issledovaniya-aquarelle-research-77-kazahstancev-stalkivalis-s-telefonnymi-moshennikami-v-yanvare-marte-2023-1311/ |
| S8 | Mobile operators blocked "свыше 77 миллионов мошеннических звонков" (over 77 million fraudulent calls) | cumulative to Jan 2026 | Digitalbusiness.kz, 2026-01-26 — https://digitalbusiness.kz/2026-01-26/kazahstantsam-rasskazali-kak-perehvativayut-zvonki-ot-moshennikov/amp/ |
| S9 | National Bank Antifraud Centre: more than 80,000 incidents since July 2024; first of the five main schemes is "ложные звонки (социальная инженерия от имени банков и госорганов)" (false calls — social engineering in the name of banks and state bodies) | Jul 2024 – Feb 2026 | Zakon.kz, 2026-02-03 — https://www.zakon.kz/mnenie/6506585-antifrodtsentr-pomog-sokhranit-19-mlrd-tenge-kazakhstantsam.html |

**Documented multi-step schemes** (used to design the scam categories and the call module):

- "Courier → eGov → Стоп-кредит": a fake courier asks for an SMS code "для подтверждения
  доставки" (to confirm delivery); then an "eGov employee" reports a hacked account; then a
  fake "служба безопасности Национального Банка" (National Bank security service).
  — National Bank of Kazakhstan, 2026-09-28, https://nationalbank.kz/ru/news/informacionnye-soobshcheniya/20338
- "Fake operator → eGov / bank → безопасный счёт": a fake mobile operator asks for an SMS code
  "для продления номера" (to extend the number); then a second caller pushes the victim to take a
  loan or move money to a "safe account".
  — АО «НИТ» via Zakon.kz, 2026-07-31, https://www.zakon.kz/obshestvo/6526598-prosyat-soobshchit-kod-iz-SMS-kazakhstantsev-predupredili-o-mnogokhodovoy-skheme-moshennikov.html

**What this tells us**

1. The problem is large and growing: about one crime in five in Kazakhstan is internet fraud (S1).
2. Calls and messages in the name of banks are the single most common scheme (S3, S4, S5, S7, S9).
   This is exactly the "fake bank" category SaqBol targets first.
3. The schemes are **conversational and multi-step**: the decisive moment is a request for an
   SMS code or a transfer during a call. Number blocking alone does not stop them, since operators
   already block tens of millions of calls (S8) and the losses still grow (S1, S2).
4. Both pensioners and young people are named as risk groups (S5, S6), so the product must work
   for an elderly user, and a relative may need to set it up for them.

## 2.2 Analysis of available data

| Data | What we found |
|---|---|
| Public Kazakh spam dataset (GitHub `Yerassyl04/Spam-kazakh`) | 184 real Kazakh messages. It is small, and it is spam-oriented rather than fraud-oriented |
| Published Kazakh spam corpus (Kumisbek & Shormakova, 2026; Zenodo) | 5,466 messages, but translated from the English SMS Spam Collection (advertising spam), so it does not show local fraud schemes |
| Our training corpus (`saqbol-ml/data/train.csv`, 2026-10-10) | 4,457 rows, but only **228 real** messages, of which 47 are scams. The rest are templates (2,020) and English translations (2,209) |
| Baseline model on real vs synthetic data | Recall (scam) is 0.97 on the full corpus but **0.47–0.51** on real messages only (see [verification plan](09-verification-plan.md#93-current-baseline)) |

Conclusion: the lack of real Kazakh/Russian fraud data is not an assumption. We measured it, and
it directly limits detection quality. Collecting real messages (task SAQ-19) is therefore part
of the project, not a side activity.

## 2.3 Interviews with potential users

**Status:** the guide is ready; interviews are being conducted (task SAQ-3, Asylbek Abdibay).
Results go in the table in §2.3.4.

### 2.3.1 Who we interview (3–5 people, at least one from each of the first three groups)

| # | Profile | Why |
|---|---|---|
| P1 | Pensioner (60+) who has received suspicious calls or SMS | Highest-risk group (S5, S6); tests whether the alert and the advice are understandable |
| P2 | Relative of an elderly person | Tests the "guardian" scenario and who would install the app |
| P3 | Young adult (18–24), active on Kaspi, OLX, marketplaces | Second risk group (S6) |
| P4 | Bank front-office, call-centre or security employee *(if available)* | Expert view on current schemes and what customers are told |
| P5 | Person who lost money or nearly did *(if willing)* | What would have stopped them at the decisive moment |

### 2.3.2 Interview guide (20–30 min, in Kazakh or Russian)

Before starting: explain the purpose, ask for consent to take notes (no audio unless they agree),
and say that no names or phone numbers will be published.

1. Over the last year, how often have you received suspicious calls or SMS? Give an example
   you remember.
2. Who did the caller or sender claim to be? What did they ask you to do?
3. How did you understand it was (or was not) fraud? What made you doubt?
4. Have you or people close to you lost money? What happened at the decisive moment?
5. What do you use now to protect yourself (operator blocking, Truecaller, Who Calls, nothing)?
   What do you like or dislike about it?
6. *(Show the SaqBol verdict card for a sample scam SMS.)* Is it clear what to do? What is
   missing or confusing?
7. Would you let an app read your SMS to check them automatically? Why or why not?
8. Would you put a suspicious call on speakerphone so the app can listen? In which situations?
9. Which language should the warning be in? How long can the warning be?
10. Would you install it for a parent or grandparent? What would stop you?

### 2.3.3 Ethics and data handling

- Participation is voluntary; the participant can stop at any time.
- Notes are anonymised (P1…P5, age range, city). No names, phone numbers or SMS texts with
  personal data are committed to the repository.
- Scam SMS that participants agree to share go into the corpus only after personal data is removed.

### 2.3.4 Findings

| ID | Profile | Date | Key findings (facts the participant reported) | Impact on requirements |
|---|---|---|---|---|
| I1 | | | | |
| I2 | | | | |
| I3 | | | | |
| I4 | | | | |
| I5 | | | | |

## 2.4 Verified findings vs assumptions

| ID | Statement | Status | Evidence / how we will check |
|---|---|---|---|
| F1 | Internet and phone fraud is a large and growing problem in Kazakhstan | ✅ verified | S1, S2 |
| F2 | Calls and messages in the name of banks are the most common scheme | ✅ verified | S3, S4, S7, S9 |
| F3 | Pensioners and young people are the main risk groups | ✅ verified | S5, S6 |
| F4 | No consumer product available in Kazakhstan analyses Kazakh or Russian message content | ✅ verified (documentation review) | [Existing systems](04-existing-systems-comparison.md); hands-on test planned (SAQ-15) |
| F5 | There is no public corpus of authentic Kazakh/Russian fraud messages; the existing Kazakh spam corpus is translated from English | ✅ verified (literature and data search) | §2.2, [Literature review](03-literature-review.md#35-gaps-the-project-addresses) |
| F6 | A model trained on synthetic templates performs much worse on real messages | ✅ verified (our experiment) | §2.2, [verification plan](09-verification-plan.md#93-current-baseline) |
| A1 | Users will paste a suspicious SMS into an app to check it | ❓ assumption | Interviews (Q6), usability test (SAQ-30) |
| A2 | Users will grant SMS-reading permission for automatic checks | ❓ assumption | Interviews (Q7) |
| A3 | Users will put a suspicious call on speakerphone so the app can listen | ❓ assumption, high risk | Interviews (Q8), usability test |
| A4 | An explanation (trigger phrases + advice) changes what the user does, compared with a bare "scam" label | ❓ assumption | Usability test: compare reactions to the verdict card with and without explanation |
| A5 | Relatives would install SaqBol for elderly family members | ❓ assumption | Interviews (Q10, P2) |
| A6 | On-device speech recognition is accurate enough in Kazakh for classification | ❓ assumption, high risk | WER test on target phones (SAQ-23) |
| A7 | Advice should be in the same language as the message | ❓ assumption | Interviews (Q9) |

Requirements that depend on an unverified assumption will be revisited after the interviews.
FR-9 … FR-12 (live call analysis) depend on A3 and A6.
