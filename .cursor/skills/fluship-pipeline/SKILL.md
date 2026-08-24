---
name: fluship-pipeline
description: Runs the Fluship release pipeline with all-optional checkbox selection, selection cache, run logs, optional log email, and fix-and-retry. Use when the user mentions run pipeline, ship, build AAB, APK, IPA, Fluship options, checkbox pipeline, or references AGENTS.md or this skill.
---

# Fluship Pipeline

Read and obey [AGENTS.md](../../../AGENTS.md) before anything else. That file is the only catalog. Do not invent extra steps and do not hide Fluship steps.

## First actions (in this order)

1. Read `.fluship-agent/pipeline-cache.json` if it exists.
2. Ask with checkboxes. Do not run pipeline commands before the answer.
   - Cache present: ask Reuse last selection or Customize.
   - Customize or no cache: `AskQuestion` with `allow_multiple: true` and every catalog id. Mark last-run ids `[saved]`.
3. Write `.fluship-agent/pipeline-cache.json` immediately after they pick.
4. Create `{workspace}/outputs/{project}/v{version}/{buildNumber}/` and `logs.txt`. Write `.fluship-agent/last-run.json`.
5. Run only selected steps in catalog order. On failure, fix, then `dart format .` and `flutter analyze` if Dart changed, then retry (max 3).
6. If `report` is selected, send logs at the end even when earlier steps failed:

```bash
dart run tool/send_pipeline_report.dart --log {logFilePath} --app-name {name} --version {version} --build-number {buildNumber} --success true --elapsed 2m10s --platforms Android --steps Clean:ok:1.2s,BuildAab:ok:3m4s
```

Do not pass the Gmail password on the command line. Read `.fluship-agent/secrets.json`.
