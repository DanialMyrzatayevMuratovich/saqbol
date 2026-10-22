# SAQ-58: Logo-blue web accent

[Task](https://saqbol.youtrack.cloud/issue/SAQ-58).

The web accent now uses the logo's middle gradient colour, `#2BA8E0`.
The darker hover colour is `#208FC8`; the ambient glow uses the same blue.
The existing dark button text (`#0B1120`) stays readable in both states.

## Before and after

Captured on 23 October 2026 in Chrome 146.0.7680.165 at 1440 × 1000, device
scale factor 1. The baseline is `51eb21525768764594bc9ad99642cbcb0d009e64`.
The after capture applies the three `globals.css` colour changes in this PR.

| Scenario | Before | After |
| --- | --- | --- |
| Login | [Screenshot](before-login.png) | [Screenshot](after-login.png) |
| Login button hovered | [Screenshot](before-login-hover.png) | [Screenshot](after-login-hover.png) |
| Dashboard | [Screenshot](before-dashboard.png) | [Screenshot](after-dashboard.png) |

All data are invented browser-intercepted fixtures: 12 users, 200 messages,
30 scam, 20 suspicious, 150 safe, and 4 call alerts. The browser used a dummy
local authentication marker. No real account, backend, message, or contact was
used. The login fields are empty.

## Contrast evidence

Computed styles were read from rendered controls after the existing hover
transition finished. Ratios use WCAG relative luminance and `(L1 + 0.05) /
(L2 + 0.05)` with the lighter colour as `L1`.

| Control | Normal text contrast | Hover text contrast |
| --- | ---: | ---: |
| Login button | 6.976:1 | 5.222:1 |
| Add model version button | 6.976:1 | 5.222:1 |
| Selected message filter | 6.976:1 | — |

Every measured state exceeds the task's 4.5:1 minimum. Detailed computed RGB
values and browser results are in [before-browser-check.json](before-browser-check.json)
and [after-browser-check.json](after-browser-check.json). Both runs reported no
page errors or unexpected browser requests. The local preview was stopped
after each capture.

## Validation

- `npm run lint` — passed.
- `npm test` — passed, 2 tests.
- `npm run build -- --webpack` — passed, including TypeScript and static page
  generation.
- Browser checks — login, dashboard, model form and selected message filter;
  normal and hover contrast measured above, logo loaded successfully.

Checks ran in an isolated copy of the tracked web files with the existing
installed dependencies and the unchanged lockfile. Webpack was selected for
the preview and build because that copy shares dependencies through a Windows
directory junction. The preview used `next dev --webpack`. Screenshots establish
appearance and contrast with mock data; they do not establish backend integration
or authentication behaviour.
