# 2. Evidence of Relevance

This page collects published statistics (secondary data), analysis of available data, and a
protocol for interviews with potential users. No completed interview records or actual-client
agreement are documented here. The last section separates **verified findings** from
**assumptions** that still need checking.

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
| Public Kazakh spam dataset (GitHub `Yerassyl04/Spam-kazakh`) | 184 unique Kazakh examples from a student course project, not confirmed received SMS. The source is spam-oriented; imported labels do not establish authentic fraud incidents |
| Published Kazakh spam corpus (Kumisbek & Shormakova, 2026; Zenodo) | 5,466 messages, but translated from the English SMS Spam Collection (advertising spam), so it does not show local fraud schemes |
| Tracked training corpus at `91862dc` (`saqbol-ml/data/train.csv`) | 2,248 rows: 2,020 template-generated examples plus **228 course/seed examples** (184 course-project examples and 44 team-written Russian seeds). Of those 228, 47 are labelled scam; none has established provenance as a received SMS |
| Expanded corpus reported in PR #25 at `37305a2` | 4,457 rows: the same 2,248 originals plus 2,209 deduplicated English translations. This branch data is not the 2,248-row main checkout above |
| Author-reported exploratory baseline on PR #25's expanded corpus | Revised grouped-CV recall is about **0.96** on all rows; protocols B and C3 report **0.47–0.51** on the 228 non-template examples. These are different protocols, not an accuracy interval or a measurement on authentic SMS traffic. See the versioned table and limitations in the [verification plan](09-verification-plan.md#93-current-baseline) |

The provenance account is documented in the [PR #25 dataset-card revision](https://github.com/DanialMyrzatayevMuratovich/saqbol/blob/37305a21be70045ef60fb8e6d8077b6aea99690b/docs/12-dataset-card.md#124-what-real-means-in-the-scripts).
The source-filter name `real` in experiment code selects examples outside sources prefixed
`synthetic`; it verifies neither human authorship nor receipt as an SMS. The 184 course examples'
creation method is not independently established. The reported scores identify a limitation of the current
diagnostic data, not real-world recall. They were not rerun for this documentation correction.

The team has not established an authentic received-SMS evaluation corpus. This does not prove
that no such resource exists: the literature includes a 189-message multilingual pilot. Collecting
and documenting authentic messages (SAQ-19) remains necessary for the proposed evaluation.

## 2.3 Interviews with potential users

**Status:** protocol prepared; completed discussions and their findings are **pending evidence**
(task SAQ-3, Asylbek Abdibay). The blank table in §2.3.4 is a template, not proof of interviews.
No substantive actual-client agreement is documented as an alternative.

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
| F4 | Reviewed product documentation leaves gaps in evidence about local Kazakh/Russian content-detection coverage | Provisional comparison finding; absence of capability is not verified from UI language or a store listing alone | [Existing systems](04-existing-systems-comparison.md); provider evidence and hands-on checks still needed (SAQ-15) |
| F5 | The team's 228 non-template examples are 184 course-project examples and 44 written seeds, not confirmed received SMS | Documented provenance limitation; an authentic evaluation corpus is still needed | §2.2 and the pinned PR #25 dataset card; this is not a claim that no public authentic corpus exists |
| F6 | The reported expanded-corpus experiments score lower on the 228 non-template examples than on the template-heavy full corpus | Author-reported exploratory result; no real-world performance claim | §2.2, [versioned evaluation table](09-verification-plan.md#93-current-baseline); not rerun for this correction |
| A1 | Users will paste a suspicious SMS into an app to check it | ❓ assumption | Interviews (Q6), usability test (SAQ-30) |
| A2 | Users will grant SMS-reading permission for automatic checks | ❓ assumption | Interviews (Q7) |
| A3 | Users will put a suspicious call on speakerphone so the app can listen | ❓ assumption, high risk | Interviews (Q8), usability test |
| A4 | An explanation (trigger phrases + advice) changes what the user does, compared with a bare "scam" label | ❓ assumption | Usability test: compare reactions to the verdict card with and without explanation |
| A5 | Relatives would install SaqBol for elderly family members | ❓ assumption | Interviews (Q10, P2) |
| A6 | A supported Kazakh recogniser is available on target phones and is accurate enough for classification | Unverified; unavailable where no supported Kazakh locale exists | Enumerate locales and verify recogniser/provider availability first; record explicit failure or a labelled fallback if absent. Only then measure Kazakh WER and end-to-end detection (SAQ-23); prepared transcripts do not verify ASR |
| A7 | Advice should be in the same language as the message | ❓ assumption | Interviews (Q9) |

Requirements that depend on an unverified assumption will be revisited after the interviews.
FR-9 … FR-12 (live call analysis) depend on A3 and A6.
