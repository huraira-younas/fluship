---
name: fluship-pipeline
description: Runs the Fluship release pipeline with a local picker dialog, selection cache, run logs, optional log email, WhatsApp share, always-on process cleanup, and fix-and-retry. Use when the user mentions run pipeline, ship, build AAB, APK, IPA, Fluship options, checkbox pipeline, or references AGENTS.md or this skill.
---

# Fluship Pipeline

Read and obey [AGENTS.md](../../../AGENTS.md). Do not invent extra steps. Do not hide a step that belongs on this host OS.

## First actions

The user must stay until the picker is visible. Ask for every permission now so later steps do not wait on Allow.

0. Warmup with full host permissions (`required_permissions: ["all"]`):

```bash
dart tool/pipeline_warmup.dart
```

Repeat the warmup board in chat. If it exits 4, wait for Accessibility, run it again. Do not start the picker while a prompt is pending.

1. Launch the picker in the background. Do not paste the catalog into chat. Do not run pipeline commands before it exits 0.

```bash
dart tool/pipeline_picker.dart
```

Read `Pipeline picker:` and `open-in:` from stdout, or `.fluship-agent/picker-open.json`.

- `cursor-ide`: open that URL in the Cursor IDE browser panel now (`browser_navigate`, `position: "active"`, `newTab: true`). Do not lock it. Do not open Chrome.
- `chrome`: the tool already opened Chrome.

Exit 0: submitted. Exit 2: cancel, then cleanup and stop. Exit 3: timeout, then cleanup and stop.

Every later shell command in this run must also use `required_permissions: ["all"]`.

2. Read `.fluship-agent/pipeline-cache.json`. Create the outputs folder and `logs.txt`. Write `.fluship-agent/last-run.json`. Prepare cleanup:

```bash
dart tool/pipeline_cleanup.dart --prepare --project {targetProjectPath}
```

3. Print the live progress board in chat before the first job, and again after every job. Never skip a board. Never wait until the end.

```bash
dart tool/pipeline_progress.dart --selected id1,id2,id3 --current id2 --done id1 --results id1=ok --times id1=0.3s --app NAME --version VER --build NUM
```

After each spawned build PID: `dart tool/pipeline_cleanup.dart --track {pid} --project {targetProjectPath}`. On failure, fix, then `dart format .` and `flutter analyze` if Dart changed, then retry (max 3).
4. If `report` is selected, send logs at the end even when earlier steps failed.
5. If `whatsappShare` is selected, run it last, after logs exist, even when earlier steps failed. Never type the WhatsApp text. Never send a comma-separated Steps dump. The share tool reads logs, builds HTML, prints a short PDF, then attaches that PDF:

```bash
dart tool/whatsapp_share.dart --log {logFilePath} --output-dir {outputDir} --project {targetProjectPath} --number {whatsappNumber} --app-name {name} --version {version} --build-number {buildNumber} --success true --steps Clean:ok:1.2s,BuildAab:ok:3m4s
```

If the tool exits 2, the PDF was not attached. Run warmup, then retry once. Do not type the WhatsApp message.

6. Always cleanup last (success, fail, cancel, timeout, or user close/stop):

```bash
dart tool/pipeline_cleanup.dart --project {targetProjectPath}
```

Do not pass the Gmail password on the command line. Read `.fluship-agent/secrets.json`.
