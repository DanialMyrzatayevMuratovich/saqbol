# 3. Literature Review

## 3.1 Method

**Questions.** (1) Which methods detect SMS scams and phone (voice) scams, and how well do they
work? (2) What works for Kazakh, Russian and code-switched Kazakh–Russian text and speech?
(3) How can a detector explain its decision to the user? (4) How should a low-resource dataset be
built and evaluated?

**Search.** ACL Anthology, Google Scholar, Semantic Scholar, OpenAlex, arXiv, IEEE Xplore and
ACM DL (via Crossref), and the journal of the National Academy of Sciences of Kazakhstan.
Search phrases: *SMS spam detection transformer*, *smishing dataset*, *vishing / voice phishing
detection transcript*, *real-time phone scam detection*, *Kazakh NLP*, *Kazakh speech recognition*,
*Kazakh–Russian code-switching*, *XLM-R low-resource*, *explainable spam detection*,
*machine translation data augmentation*, *LLM scam detection*.

**Inclusion.** Peer-reviewed papers from 2021–2026, plus foundational works that the project
directly builds on (BERT-style pre-training, XLM-R, LIME, the SMS Spam Collection). Preprints are
used only as supporting material and are marked. Every source was opened (publisher, ACL
Anthology, Crossref or arXiv page) to confirm authors, year and venue. Numbers are quoted as the
authors report them.

**Result.** 25 sources are analysed below: 23 peer-reviewed journal and conference papers and
2 short peer-reviewed abstracts ([12], [13]). 21 are from 2021–2026; the other 4 are foundational
works ([1], [14], [23], [24]).

## 3.2 Analysis table

Type: J = journal, C = conference, A = extended / student abstract.

| # | Source | Type | Task, language | Method | Data | Key result (as reported) | Limitation | Used in SaqBol for |
|---|---|---|---|---|---|---|---|---|
| [1] | Almeida et al., 2011 | C | SMS spam, EN | Classical classifiers | SMS Spam Collection: 5,574 SMS, 747 spam | Benchmark corpus | English, 2011, commercial spam not fraud | Foundational benchmark; source of [6]'s Kazakh corpus |
| [2] | Liu, Lu & Nayak, 2021 | J | SMS spam, EN | Modified Transformer vs classical ML | SMS Spam Collection, UtkMl Twitter | Accuracy 98.92%, recall 0.9451, F1 0.9613 | Old English benchmark | Motivates the transformer stage |
| [3] | Salman, Ikram & Kaafar, 2024 | J | SMS spam, EN | Shallow ML vs DL vs commercial filters, under evasion | 68K+ SMS (39% spam) | Most shallow methods and filters "performed inadequately"; all approaches vulnerable to evasion | English | Baseline is only a baseline; robustness tests |
| [4] | Uddin et al., 2025 | J | SMS spam, EN | Fine-tuned RoBERTa + LIME + back-translation | 5,574 → 9,650 balanced | RoBERTa accuracy 99.84%; SVM 97.85% (imbalanced) | One old benchmark; balanced test may inflate | Explainability + augmentation template |
| [5] | Mishra & Soni, 2023 | J | Smishing | URL domain check + neural classifier | SMS datasets | Accuracy 97.93% | Few handcrafted features; needs URLs | Combining text with a non-text signal (number reputation) |
| [6] | Kumisbek & Shormakova, 2026 | J | SMS spam, **KZ** | LR / SVM / MNB vs zero-shot LLMs vs NLI vs mBERT, DistilmBERT, XLM-R + LoRA | 5,466 Kazakh SMS translated from [1] | All LoRA models > 0.99 accuracy; XLM-R macro-F1 0.99; NLI zero-shot recall 20–61%; LLMs "struggle with Kazakh morphology and code-switched text" | "Controlled translated conditions"; translation artifacts | Closest prior work; XLM-R + fine-tuning over zero-shot LLMs |
| [7] | Serek et al., 2026 | J | Fraud messages, **RU/KZ/EN** | TF-IDF + LR, LinearSVM, MNB, RF, XGBoost; recall as safety metric | 189 messages from messengers and news | LR, LinearSVM: accuracy 0.97, recall 1.00; NB accuracy 0.79 | Tiny pilot dataset | Same baseline design; recall-first metric |
| [8] | Radolda et al., 2026 | C | Phishing SMS / e-mail, **EN/RU/KZ** | TF-IDF models, XLM-R, hybrid with URL heuristics | 720 synthetic messages | Linear models F1 = 1.00, attributed by the authors "entirely to the artificial lexical gap" | Synthetic data | Evidence for a real-only test set |
| [9] | Derakhshan, Harris & Behzadi, 2021 | C | Phone scam, EN | "Scam signatures" (speech acts) + embeddings | Volunteer-written scam scripts | "High accuracy" | Not real calls | Scam stages as cues (trigger phrases) |
| [10] | Moussavou Boussougou & Park, 2023 | J | Voice phishing, KO | 1D-CNN + BiLSTM + attention, FastText | KorCCVi v2 transcripts | Accuracy 99.32%, F1 99.31% | Small set; offline whole transcripts | Transcript classification works outside English |
| [11] | Cho & Seo, 2025 | C | Smishing + vishing, KO | LMs on edge devices; Whisper-small STT; 16-token segments accumulated from call start | 94,602 phishing / 205,870 non-phishing | At recall 1, 86.95% of phishing calls caught in the first 20% of the call | ASR + classifier every 16 tokens is costly | Closest architecture: accumulating window, STT choice, hard negatives |
| [12] | Shen et al., 2025a | A | Phone scam, ZH | GPT-4, GPT-4o and others vs Random Forest | Public synthetic sets, real calls, keyword-controlled set | RF 1.00 on public sets but recall 0.16 on keyword-controlled set; LLM recall "as low as 0.72" | Short abstract; biased datasets | Keyword shortcuts; hard negatives |
| [13] | Shen et al., 2025b | A | Real-time phone scam, ZH | LLM verdict after each speaker turn; optional UNCERTAIN | Real + synthetic calls | Real-time recall 0.98–1.00, precision 0.70–0.77 on synthetic, vs 0.95–1.00 after the call | No user study | Timeliness vs precision trade-off; alert threshold |
| [14] | Conneau et al., 2020 | C | Multilingual pre-training | XLM-R, 100 languages | CC-100; Kazakh 476M tokens | +14.6% XNLI accuracy over mBERT | "Curse of multilinguality" | Main model choice |
| [15] | Yeshpanov, Khassanov & Varol, 2022 | C | NER, KZ | CRF, BiLSTM-CNN-CRF, mBERT, XLM-R | KazNERD: 112,702 sentences | F1: mBERT 96.24%, XLM-R 97.22% | News domain | XLM-R over mBERT for Kazakh |
| [16] | Yeshpanov & Varol, 2024 | C | Sentiment, KZ | mBERT, XLM-R, RemBERT, mBART-50 | KazSAnDRA: 180,064 reviews | Polarity F1 0.81 (XLM-R, RemBERT) | — | Real Kazakh text is mixed-script and code-switched |
| [17] | Yeshpanov, 2026 | C | Sentiment, **KZ / RU / code-switched** | SVM, LR, MNB, mBERT, XLM-R, RemBERT | 100,502 reviews | Macro-F1: XLM-R 0.81, mBERT 0.74, SVM 0.73, LR 0.71, MNB 0.70; code-switched 0.76 vs Russian 0.81 (RemBERT) | Long reviews, not messages | Expected ranking of our models; code-switching is harder |
| [18] | Yeshpanov et al., 2024 | C | QA, KZ | Machine-translated data for training only, real exam questions for test | ~61,000 MT triples | — | — | Precedent for "synthetic/translated for training, real for testing" |
| [19] | Mussakhojayeva, Khassanov & Varol, 2022 | C | ASR, KZ | Corpus | KSC2: > 1,000 h, incl. KZ–RU code-switching | — | — | STT fine-tuning resource |
| [20] | Radford et al., 2023 | C | ASR, multilingual | Whisper, weak supervision | 680,000 h | — | — | STT candidate |
| [21] | Li et al., 2024 | C | ASR, KZ | Whisper + LM fusion + pseudo-label fine-tuning | Fleurs, KSC | Off-the-shelf Whisper-large WER 43.58% (Fleurs), 56.18% (KSC); best 32.36% | Read speech, not calls | Off-the-shelf Kazakh STT is weak → measure WER, tolerate noise |
| [22] | Doğruöz et al., 2021 | C | Code-switching survey | — | — | Language technologies handle code-switching poorly | Survey | Code-switching as a separate challenge |
| [23] | Ribeiro, Singh & Guestrin, 2016 | C | Explainability | LIME | — | — | Local, approximate | Explanations for the transformer model |
| [24] | Jain & Wallace, 2019 | C | Explainability | Attention vs gradient importance | — | Attention weights often disagree with feature importance | — | Do not use raw attention as the explanation |
| [25] | Artetxe et al., 2023 | C | Cross-lingual classification | Translate-train vs translate-test | — | MT-based approaches "substantially better than previously assumed"; train/test mismatch matters | — | Translation augmentation; keep test set real |

## 3.3 Critical review

### SMS spam and smishing detection

SMS spam detection is a mature task in English. The SMS Spam Collection [1] is still the default
benchmark more than ten years after its release, and on it both transformers [2], [4] and tuned
classical models reach about 98–99% accuracy [4]. These scores say little about fraud in practice.
The benchmark is small, old and English, and its "spam" is mostly advertising. When Salman et al.
[3] built a larger, newer corpus and tested evasion techniques, most shallow models and commercial
filters "performed inadequately". Every approach could be evaded. Two lessons follow for SaqBol.
First, the TF-IDF model is a baseline and a fallback, not the end goal. Second, robustness to
obfuscation (Latin–Cyrillic mixing, look-alike domains, character substitution) has to be tested.
Mishra and Soni [5] show that adding a non-text signal (domain checks) helps. In SaqBol that role
is played by the sender-number reputation and the look-alike-domain rules.

### Work on Kazakhstan

Three recent papers address Kazakh or Kazakhstan-specific messages, and each shows a different
limitation of the available data. Kumisbek and Shormakova [6] built a Kazakh spam corpus by
translating [1]. After LoRA fine-tuning, all multilingual encoders exceed 0.99 accuracy, while
zero-shot NLI models and instruction-tuned LLMs perform poorly on Kazakh and code-switched input.
This is the closest prior work. It supports our choice of a fine-tuned XLM-R over prompting an
LLM. However, its data is translated English advertising spam, and the authors themselves call for
native user-generated corpora. Serek et al. [7] use real Russian, Kazakh and English fraud
messages with the same TF-IDF baselines and recall-first evaluation as SaqBol, but only 189 of
them. Radolda et al. [8] generate 720 synthetic messages and get F1 = 1.00, which they attribute
"entirely to the artificial lexical gap" between template classes. Our own baseline behaves the
same way: recall falls from 0.97 on the template-heavy corpus to about 0.5 on real messages
([verification plan](09-verification-plan.md#93-current-baseline)). Taken together, [6]–[8] mean
that a high score on translated or synthetic data is not evidence of real-world performance.

### Phone-scam (vishing) detection

Voice-scam detection usually works on transcripts. Derakhshan et al. [9] describe scams as
sequences of speech acts ("scam signatures"), the same idea as SaqBol's trigger phrases for a
call ("служба безопасности" → "назовите код"). Korean work shows that transcript classifiers can be
very accurate on complete calls [10]. The real-time setting is harder. Cho and Seo [11] run
Whisper on the device, classify 16-token segments accumulated from the start of the call, and
catch 86.95% of phishing calls within the first 20% of the call at full recall. They also add
benign examples that contain scam keywords, to stop the model from relying on keywords alone.
Shen et al. [12] show why that matters: a Random Forest scoring 1.00 on public synthetic sets
dropped to recall 0.16 on a keyword-controlled set. Shen et al. [13] measured the cost of
deciding early: real-time recall stays high, but precision on synthetic calls falls to 0.70–0.77,
against 0.95–1.00 when the whole call is analysed. An "uncertain" option improves precision
but delays the alert. SaqBol's design follows from these papers: an accumulating sliding window,
a high alert threshold (0.8) with a lower "suspicious" band, hard negatives such as genuine bank
and OTP messages, and measuring time-to-alert as well as accuracy. None of these studies covers
Kazakh or Russian.

### Multilingual models and Kazakh NLP

XLM-R [14] includes Kazakh (476M tokens in CC-100) and Russian in pre-training and outperforms
mBERT, especially on lower-resource languages. Kazakh benchmarks agree. On named entity
recognition XLM-R beats mBERT (97.22 vs 96.24 F1) [15]. On Kazakh, Russian and code-switched
reviews, XLM-R (0.81) beats mBERT (0.74) and TF-IDF with SVM, LR and NB (0.73, 0.71, 0.70) [17].
This is the same set of baselines SaqBol uses, which lets us predict the expected ranking. The
same study finds code-switched text the hardest subset. KazSAnDRA [16] confirms that real
Kazakh user text mixes Kazakh and Russian words and sometimes uses Latin script. KazQAD [18]
gives a published precedent for our evaluation rule: machine-translated data is used for training
only, and the test set is original Kazakh. Surveys of code-switching [22] note that language
technologies handle it poorly, so we report code-switched messages as a separate slice.

### Speech recognition for Kazakh

Live call analysis is only as good as its transcript. Whisper [20] supports Kazakh, but
off-the-shelf Whisper-large has a WER of 43.58% on Fleurs and 56.18% on the Kazakh Speech Corpus.
Fine-tuning and language-model fusion lower it to 32.36% [21]. KSC2 [19] provides more than 1,000
hours of Kazakh speech, including Kazakh–Russian code-switching, for fine-tuning. Cho and Seo [11]
found that ASR quality strongly affects detection. SaqBol currently uses the phone's built-in
recogniser (see [Technology comparison](05-technology-comparison.md#55-speech-to-text-for-live-call-analysis)).
The literature says this choice must be measured (WER on our own recordings), and that the
classifier must tolerate recognition errors.

### Explainability

LIME [23] gives model-agnostic local explanations, and Uddin et al. [4] applied it to SMS spam with
a transformer. Jain and Wallace [24] show that attention weights are not a faithful explanation.
For the linear baseline, the explanation is faithful by construction: the highlighted n-grams are
the features with the largest weights that are present in the message. For XLM-R we will use an
attribution method (LIME or SHAP) rather than raw attention.

### Data augmentation by translation

Artetxe et al. [25] show that machine translation is a stronger tool for cross-lingual
classification than often assumed. They also show that the mismatch between translated and
original text matters. SaqBol uses translation and templates to enlarge the training set and keeps
the test set real. This also follows [18] and the warnings in [6] and [8].

## 3.4 What SaqBol takes from the literature

| Decision | Supported by |
|---|---|
| TF-IDF + LR as a baseline, compared with LinearSVM and NB | [3], [7], [17] |
| Fine-tuned XLM-R as the main model, not a prompted LLM | [6], [14], [15], [17] |
| Recall on the scam class as the primary metric, FPR as the constraint | [7], [11], [12] |
| Real-only test set; synthetic and translated data for training only | [6], [8], [18], [25] |
| Hard negatives (benign messages containing scam keywords) | [11], [12] |
| Accumulating sliding window and a high alert threshold for calls | [11], [13] |
| Measure STT word error rate for Kazakh; classifier must tolerate ASR noise | [11], [19], [21] |
| Separate evaluation slice for code-switched messages | [16], [17], [22] |
| Explanation via feature weights (baseline) and LIME/SHAP (XLM-R), not attention | [4], [23], [24] |
| Number reputation and domain rules as extra signals | [5] |

## 3.5 Gaps the project addresses

1. **No authentic Kazakh/Russian fraud corpus.** Existing Kazakh resources are translated English
   advertising spam [6], a 189-message pilot [7] or synthetic messages [8].
2. **Code-switching is not evaluated in scam detection.** Kazakh–Russian code-switching has been
   studied for speech recognition [19] and sentiment [16], [17], but none of the reviewed scam or
   spam detectors reports results on code-switched messages.
3. **No real-time phone-scam detection for Kazakh or Russian.** Transcript-based work exists for
   Korean [10], [11] and Chinese [12], [13]. Kazakh STT is the weak link [21].
4. **Explained warnings in a low-resource language.** In the reviewed literature, explainable
   SMS detection exists only for English [4]. None of the reviewed systems combines message content
   with sender reputation and explains the decision in Kazakh or Russian.

## 3.6 References

[1] T. A. Almeida, J. M. Gómez Hidalgo, and A. Yamakami, "Contributions to the study of SMS spam filtering: new collection and results," in *Proc. 11th ACM Symp. Document Engineering (DocEng '11)*, 2011, pp. 259–262. doi:10.1145/2034691.2034742

[2] X. Liu, H. Lu, and A. Nayak, "A spam transformer model for SMS spam detection," *IEEE Access*, vol. 9, pp. 80253–80263, 2021. doi:10.1109/ACCESS.2021.3081479

[3] M. Salman, M. Ikram, and M. A. Kaafar, "Investigating evasive techniques in SMS spam filtering: A comparative analysis of machine learning models," *IEEE Access*, vol. 12, pp. 24306–24324, 2024. doi:10.1109/ACCESS.2024.3364671

[4] M. A. Uddin, M. N. Islam, L. Maglaras, H. Janicke, and I. H. Sarker, "ExplainableDetector: Exploring transformer-based language modeling approach for SMS spam detection with explainability analysis," *Digital Communications and Networks*, vol. 11, no. 5, pp. 1504–1518, 2025. doi:10.1016/j.dcan.2025.07.008

[5] S. Mishra and D. Soni, "DSmishSMS—A system to detect smishing SMS," *Neural Computing and Applications*, vol. 35, no. 7, pp. 4975–4992, 2023. doi:10.1007/s00521-021-06305-y

[6] M.-A. Kumisbek and A. Shormakova, "Applying large language models to spam detection in the Kazakh low-resource language setting," *Scientific Reports*, vol. 16, art. 30145, 2026. doi:10.1038/s41598-026-60445-6

[7] A. Serek, A. Shoiynbek, M. Zheludkov, D. Kuanyshbay, and B. Meraliyev, "Сравнительный анализ методов машинного обучения для выявления мошенничества в текстовых сообщениях" [Comparative analysis of machine learning methods for detecting fraud in text messages], *News of the National Academy of Sciences of the Republic of Kazakhstan* (ISSN 2518-1726), no. 3, pp. 365–383, 2026. doi:10.32014/2026.2518-1726.468

[8] Y. Radolda, R. Muratkhan, A. Shaikhanova, D. Satybaldina, and G. Abisheva, "A safety-constrained platform for multilingual phishing simulation and hybrid detection across mobile and email channels in English, Russian, and Kazakh," *Procedia Computer Science*, vol. 290, pp. 101–108, 2026. doi:10.1016/j.procs.2026.08.373

[9] A. Derakhshan, I. G. Harris, and M. Behzadi, "Detecting telephone-based social engineering attacks using scam signatures," in *Proc. 2021 ACM Workshop on Security and Privacy Analytics (IWSPA '21)*, 2021, pp. 67–73. doi:10.1145/3445970.3451152

[10] M. K. Moussavou Boussougou and D.-J. Park, "Attention-based 1D CNN-BiLSTM hybrid model enhanced with FastText word embedding for Korean voice phishing detection," *Mathematics*, vol. 11, no. 14, art. 3217, 2023. doi:10.3390/math11143217

[11] H. Cho and M. Seo, "Towards reliable and practical phishing detection," in *Proc. NAACL 2025 (Vol. 3: Industry Track)*, 2025, pp. 210–225. doi:10.18653/v1/2025.naacl-industry.18

[12] Z. Shen, K. Wang, Y. Zhang, G. Ngai, and E. Y. Fu, "Combating phone scams with LLM-based detection: Where do we stand? (Student abstract)," in *Proc. AAAI Conf. Artificial Intelligence*, vol. 39, no. 28, 2025, pp. 29487–29489. doi:10.1609/aaai.v39i28.35298

[13] Z. Shen, S. Yan, Y. Zhang, X. Luo, G. Ngai, and E. Y. Fu, "'It warned me just at the right moment': Exploring LLM-based real-time detection of phone scams," in *Extended Abstracts of CHI 2025*, 2025, pp. 1–7. doi:10.1145/3706599.3720263

[14] A. Conneau, K. Khandelwal, N. Goyal, V. Chaudhary, G. Wenzek, F. Guzmán, E. Grave, M. Ott, L. Zettlemoyer, and V. Stoyanov, "Unsupervised cross-lingual representation learning at scale," in *Proc. ACL 2020*, 2020, pp. 8440–8451. doi:10.18653/v1/2020.acl-main.747

[15] R. Yeshpanov, Y. Khassanov, and H. A. Varol, "KazNERD: Kazakh named entity recognition dataset," in *Proc. LREC 2022*, 2022, pp. 417–426. https://aclanthology.org/2022.lrec-1.44

[16] R. Yeshpanov and H. A. Varol, "KazSAnDRA: Kazakh sentiment analysis dataset of reviews and attitudes," in *Proc. LREC-COLING 2024*, 2024, pp. 9657–9667. https://aclanthology.org/2024.lrec-main.844

[17] R. Yeshpanov, "100,000+ movie reviews from Kazakhstan: Russian, Kazakh, and code-switched texts," in *Proc. NLP4DH 2026*, 2026, pp. 31–40. doi:10.18653/v1/2026.nlp4dh-1.4

[18] R. Yeshpanov, P. Efimov, L. Boytsov, A. Shalkarbayuli, and P. Braslavski, "KazQAD: Kazakh open-domain question answering dataset," in *Proc. LREC-COLING 2024*, 2024, pp. 9645–9656. https://aclanthology.org/2024.lrec-main.843

[19] S. Mussakhojayeva, Y. Khassanov, and H. A. Varol, "KSC2: An industrial-scale open-source Kazakh speech corpus," in *Proc. Interspeech 2022*, 2022, pp. 1367–1371. doi:10.21437/Interspeech.2022-421

[20] A. Radford, J. W. Kim, T. Xu, G. Brockman, C. McLeavey, and I. Sutskever, "Robust speech recognition via large-scale weak supervision," in *Proc. ICML 2023*, PMLR vol. 202, 2023, pp. 28492–28518. https://proceedings.mlr.press/v202/radford23a.html

[21] J. Li, Y. Pu, Q. Sun, and W.-Q. Zhang, "Improving Whisper's recognition performance for under-represented language Kazakh leveraging unpaired speech and text," in *Proc. Interspeech 2024*, 2024, pp. 2514–2518. doi:10.21437/Interspeech.2024-1790

[22] A. S. Doğruöz, S. Sitaram, B. E. Bullock, and A. J. Toribio, "A survey of code-switching: Linguistic and social perspectives for language technologies," in *Proc. ACL-IJCNLP 2021*, 2021, pp. 1654–1666. doi:10.18653/v1/2021.acl-long.131

[23] M. T. Ribeiro, S. Singh, and C. Guestrin, "'Why should I trust you?': Explaining the predictions of any classifier," in *Proc. KDD 2016*, 2016, pp. 1135–1144. doi:10.1145/2939672.2939778

[24] S. Jain and B. C. Wallace, "Attention is not explanation," in *Proc. NAACL-HLT 2019*, 2019, pp. 3543–3556. doi:10.18653/v1/N19-1357

[25] M. Artetxe, V. Goswami, S. Bhosale, A. Fan, and L. Zettlemoyer, "Revisiting machine translation for cross-lingual classification," in *Proc. EMNLP 2023*, 2023, pp. 6489–6499. doi:10.18653/v1/2023.emnlp-main.399

### Further reading (not used in the analysis above)

- J. Devlin et al., "BERT," NAACL-HLT 2019, doi:10.18653/v1/N19-1423 — pre-training and fine-tuning.
- T. Pires et al., "How multilingual is multilingual BERT?," ACL 2019, doi:10.18653/v1/P19-1493.
- S. M. Lundberg and S.-I. Lee, "A unified approach to interpreting model predictions (SHAP)," NeurIPS 2017.
- Z. Ma et al., "TeleAntiFraud-28k," ACM MM 2025, doi:10.1145/3746027.3755835 — audio + text fraud detection.
- P. Wang et al., "SAFE-QAQ," ACL 2026, doi:10.18653/v1/2026.acl-long.1201 — end-to-end audio fraud detection.
- M. Hur et al., "Are large language models effective for detecting spam messages?," *Int. J. Information Security*, 2026, doi:10.1007/s10207-026-01283-5.
