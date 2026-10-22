---
id: 20261022T191242Z-danial-small-tasks-you-can-pr-into-main-now
from: danial
to: asylbek
type: task
task: SAQ-84
in_reply_to:
status: open
created: 2026-10-22T19:12:42Z
closed:
subject: Small tasks you can PR into main now (your #27 and #29 are merged)
---

Danial merged your #27 and #29 into main (merge commits d325ad0, 14fa97b) — your commits 6956c5e and 5124c56 are in main under your name. Thank you.

Next: small tasks from your YouTrack list that touch files no open PR changes, so each can go straight into main. One task = one branch from up-to-date main (SAQ-<id>-<slug>) = one PR, reviewer DanialMyrzatayevMuratovich. Danial reviews and merges with a merge commit, so your commits land in main. Suggested order:

1. SAQ-84: app name "SaqBol" (android:label in AndroidManifest.xml; CFBundleDisplayName/CFBundleName in ios/Runner/Info.plist). ~10 min. #26 also edits the manifest but other lines; git merges it.
2. SAQ-58: web accent to the logo blue (saqbol-web/src/app/globals.css --accent/--accent-strong; keep button text contrast >= 4.5:1; before/after screenshot).
3. SAQ-62: mask user phone numbers in the web Messages table (+7 700 *** ** 01), sender numbers stay full; a vitest unit test for the mask function.
4. SAQ-61: paginate the Messages table, 25 rows per page (after SAQ-62, same file).
5. SAQ-63: SUS questionnaire in Kazakh and Russian as a new docs/usability/ file, with the scoring formula.
6. SAQ-64: one-page user guide, docs/user-guide-kk.md and docs/user-guide-ru.md.
7. SAQ-83: open an issue on github.com/Yerassyl04/Spam-kazakh asking permission to use kazspam.csv (no commit needed yet; note the link in YouTrack).

After #15/#19/#20 are merged: SAQ-48 (Kazakh proofreading, incl. the new strings in #20), SAQ-59/60 (web strings + kk/en), SAQ-47 (scan duplicates), SAQ-57 (web light theme).

Please run the relevant checks (npm run lint && npm test; flutter analyze for the manifest change if you have Flutter) and say in each PR what you ran. Reply here with the PR numbers as you open them.
