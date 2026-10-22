# SaqBol documentation

Read the [implementation and evidence status](implementation-evidence.md) before presenting
capability or evaluation claims. It distinguishes the reviewed `main` baseline from unmerged
ML/mobile work, Kazakh text processing from speech recognition, and course/seed examples from
authenticated received SMS. Two informal user conversations are recorded; structured interviews,
client agreement and supervisor feedback are still pending.

| # | Document | Contents |
|---|---|---|
| 1 | [Project proposal](01-project-proposal.md) | Title, team, problem, users, aim, objectives, outcomes, scope, status |
| 2 | [Evidence of relevance](02-relevance-evidence.md) | Statistics for Kazakhstan, data analysis, interviews, verified findings vs assumptions |
| 3 | [Literature review](03-literature-review.md) | 25 sources, analysis table, critical review, gaps |
| 4 | [Existing systems comparison](04-existing-systems-comparison.md) | 5 systems × 10 criteria, with evidence |
| 5 | [Technology comparison](05-technology-comparison.md) | 7 key decisions with alternatives |
| 6 | [Requirements draft, PR #8](https://github.com/DanialMyrzatayevMuratovich/saqbol/blob/46a3364f95f81ab53cd0bc5b658a921ec53547db/docs/06-requirements.md) | Functional/non-functional requirements and acceptance criteria; pending review/merge, with [SAQ-86 clarification patch](reviews/README.md) |
| 7 | [Architecture](07-architecture.md) | Context, use case, component, sequence and data diagrams; decisions; alignment |
| 8 | [Prototype](08-prototype.md) | Screens, API examples, how to run |
| 9 | [Verification and evaluation plan](09-verification-plan.md) | Test levels, current baseline, ML protocol, call and usability evaluation |
| 10 | [Project management and risks](10-project-management.md) | Roles, workflow, milestones, task plan, risks, dependencies |
| 11 | [Supervisor feedback](11-supervisor-feedback.md) | Review log |

Diagram sources: [`diagrams/src/`](../diagrams/src) · exports: [`diagrams/export/`](../diagrams/export)

Review evidence: [22 October 2026 pre-defense review](reviews/2026-10-22-pre-defense-review.md)
(published PR reviews, actual checks, and unresolved submission dependencies; SAQ-13).

`SaqBol_TZ.md` in the repository root is the original specification draft (in Russian, July 2026).
Where it differs from these documents (for example NestJS vs Go), these documents describe the
current state.
