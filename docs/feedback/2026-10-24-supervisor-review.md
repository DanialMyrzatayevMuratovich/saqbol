# Supervisor review supplied after the first pre-defense submission

**Supervisor named by the team:** Zhibek Nurzhanovna Sarsenova
**Recorded:** 24 October 2026
**Source:** screenshot supplied by Asylbek Abdibay of a Telegram message forwarded from
"Zhibek", followed by a request to upload the supervisor's feedback to GitHub.
**Original review date and reviewed commit:** not established by the supplied screenshot.
**Task and response:** [SAQ-14](https://saqbol.youtrack.cloud/issue/SAQ-14) ·
[team decisions and actions](../11-supervisor-feedback.md)

The text below is transcribed from the supplied screenshot; display line wrapping is removed.
It preserves the supervisor's assessment, including the missing-feedback and missing-name
observations. The current repository status and the team's response are recorded separately
in the action log. This transcription is not a signed report or a final committee grade.
The private chat screenshot is not included in the public repository.

## Review text

> The graduation project by Danial Myrzatayev and Asylbek Abdibay, “SaqBol,” is a prototype system for detecting fraudulent SMS messages and phone calls in Kazakh and Russian. The topic is relevant: according to the team’s sources, internet and phone fraud accounts for about one in five registered crimes in Kazakhstan, with 28.9 thousand cases in 2025. Existing protection tools offer limited support for content analysis in Kazakh.
>
> The problem is clearly defined, and the scope is explicitly bounded. The project involves substantial engineering complexity: a Go backend, a Python ML service connected over gRPC, a Flutter mobile application with Android call screening, and a Next.js administrative dashboard. The team has prepared the literature review, the existing system and technology comparisons, requirements, architectural diagrams with editable PlantUML sources, and a verification plan. Responsibilities are clearly allocated, and the development workflow follows the required rules: YouTrack tasks, task-named branches, reviewed pull requests, and a protected main branch.
>
> The implementation is notably ahead of the requirements for this stage. The backend, the TF-IDF baseline classifier and the web dashboard are already working. The system can be launched with a single command, and automated tests are provided for all components. The team also clearly distinguishes verified results from assumptions, including the origin of the training data, the exploratory nature of the reported recall, and the unverified status of Kazakh speech recognition.
>
> At the same time, two components required for the first pre-defense are missing: evidence of relevance from interviews with potential users, and supervisor feedback. The supervisor is also not specified in the README.
>
> Overall, the work meets most of the requirements of the first pre-defense and can be graded “good.”
