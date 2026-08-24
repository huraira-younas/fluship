# Fluship Agent Guide

Reference this file (`@AGENTS.md`) before any Fluship work: run pipeline, ship, build, or change this repo.

## App vs agent

Fluship is a Flutter GUI release cockpit. The app Config tab and Run button stay as they are. Do not change `lib/` for an agent pipeline run.

There is no `fluship run` CLI. When the user wants the **app**, they use the app. When they want the **agent**, they say run pipeline (or ship / build AAB / IPA) and you follow this file.

Picker and cache live in the **Fluship workspace** (this repo). `targetProjectPath` is the Flutter app to build. Outputs stay under this workspace `outputs/` folder.

## Hard rules

- Every catalog step is optional. Never invent a default set on a first run.
- Show is not select. Windows shows the full Android set. macOS shows the full catalog. First run checks nothing.
- Never hide a step that belongs on this host OS. On Windows and Linux, omit iOS ids. On macOS, show iOS ids even when they are blocked.
- Never start pipeline commands before the picker exits 0.
- Ask for every host permission at the start. Do not start a long step while a permission dialog is pending.
- If the user already named steps, still open the picker. Do not silently add extras.
- Logs are mandatory every run (not a checkbox). Create the run folder and `logs.txt` before the first step.
- While steps run, always show a live progress board in chat (NOW / DONE / WAIT). Do not stay silent until the end.
- Do not commit, push, upload stores, email, or run power actions unless those exact ids were selected. Power needs a second confirm after the picker.
- Do not swallow git failures. The GUI uses `|| true`. You must not.
- Critical ids abort later steps: `bumpVersion`, `clean`, `pubGet`, `pubUpgrade`. Then offer fix and continue.
- After any Dart edit in this repo, run `dart format .` and `flutter analyze`.
- Never commit `.fluship-agent/secrets.json`. Never print the app password.
- No em-dashes in comments, markdown, or user-facing text you write in this repo.

## Protocol

0. Ask for permissions first. The user must stay until the picker is on screen.

```bash
dart tool/pipeline_warmup.dart
```

Run that command with full host permissions (`required_permissions: ["all"]`). Cursor will show Allow. macOS may show Accessibility and Automation prompts for System Events, Finder, and WhatsApp. Repeat the warmup board in chat. Tell the user: stay, click Allow (and Always allow if shown), do not leave yet.

If warmup exits 4, Accessibility is still missing. The tool opens the Accessibility settings. Wait for the user to enable Cursor, run warmup again, then continue. Do not launch the picker or a build while a prompt is waiting.

Every later shell command in this same run must also use full host permissions (`required_permissions: ["all"]`). Do not switch to a sandboxed command after the user has left.

1. Launch the picker from the Fluship workspace. Do not paste the catalog into chat.

```bash
dart tool/pipeline_picker.dart
```

Start it in the background so you can read stdout before it exits. Do not use `flutter` or `dart run` to start the picker.

Stdout looks like:

```
Pipeline picker: http://127.0.0.1:PORT/
open-in: cursor-ide
```

The same data is in `.fluship-agent/picker-open.json`.

- If `open-in` is `cursor-ide`: open that URL in the Cursor IDE browser panel now (`browser_navigate`, `position: "active"`, `newTab: true`). Do not lock the browser. The user must click the picker. Do not open Chrome.
- If `open-in` is `chrome`: the tool already opened Chrome. Do not also open the IDE panel.

Tell the user where the picker is. Exit 0 means submit. Exit 2 means cancel. Exit 3 means timeout. Any other code is an error. On cancel, timeout, or error, stop. Do not run steps.

2. Read `.fluship-agent/pipeline-cache.json`. Use `targetProjectPath` as the working directory for Flutter and git commands.
3. Create `{workspace}/outputs/{sanitizedProject}/v{version}/{buildNumber}/` and `logs.txt`. Write `.fluship-agent/last-run.json`.
4. Print a live progress board in chat before the first step, then again before and after every step. Do not wait until the end. The user must always see which job is NOW, which are DONE, and which are still WAIT.

```bash
dart tool/pipeline_progress.dart --selected bumpVersion,clean,pubUpgrade --current clean --done bumpVersion --results bumpVersion=ok
```

Example board:

```
Pipeline progress
1. [DONE] Set app version
2. [NOW] Clean old build files
3. [WAIT] Upgrade packages
```

Use `[NOW]`, `[WAIT]`, and a result (`[OK]`, `[FAIL]`, `[SKIP]`, or `[DONE]`) for every selected id. Human names come from the tool. Never hide a selected step.
5. Run only selected ids that are still enabled on this host OS, in catalog order. Ignore iOS ids on Windows and Linux even if an older Mac cache saved them.
6. If a mutex pair is both present, keep the first in catalog order and skip the other.
7. If `bumpVersion` or any git step is selected and version, build number, or branch is missing, ask and reuse cache values when present. Default branch is `master`.
8. Append every command, stdout, stderr, status, and retry to `logs.txt`.
9. On failure: diagnose from the log, fix the real cause, `dart format .` then `flutter analyze` if Dart changed, retry that step. Max 3 retries. Then continue or abort per critical rules. You may resume from the failed step.
10. If `report` is selected, send the email at the end even when earlier steps failed.
11. If `whatsappShare` is selected, share after logs exist, even when earlier steps failed. Never type a WhatsApp message by hand. Never paste a comma-separated `Steps:` line into WhatsApp or chat. Always run:

```bash
dart tool/whatsapp_share.dart --log {logFilePath} --output-dir {outputDir} --project {targetProjectPath} --number {whatsappNumber} --app-name {name} --version {version} --build-number {buildNumber} --success true --steps Clean:ok:1.2s,BuildAab:fail:3m4s
```

That tool writes `pipeline-report.pdf` first, opens WhatsApp Desktop on macOS with a two-line status, and pastes the PDF plus a fat APK or `armeabi-v7a` and `arm64-v8a` splits. It does not press Send. If paste fails, it reveals the PDF in Finder. File paste needs Mac Accessibility for Terminal or Cursor. Do not use a WhatsApp Cloud API. Do not send text without the PDF.
12. If a power id is selected, ask one second confirm. Do not run power without that yes.
13. Always clean processes last, including when the user says close or stop, and after success, fail, cancel, or timeout:

```bash
dart tool/pipeline_cleanup.dart --project {targetProjectPath}
```

Before the first command: `dart tool/pipeline_cleanup.dart --prepare --project {targetProjectPath}`. After you start a build process, `dart tool/pipeline_cleanup.dart --track {pid} --project {targetProjectPath}`. On close/stop also pass `--close-picker`.
14. Summarize: selected ids, each status, log path, email result, WhatsApp result. Include the final progress board.

## Project selection

The picker asks for the project on every run.

- First run (no `targetProjectPath` in cache): project is empty. The user must pick or browse.
- Later runs: last `targetProjectPath` is the default if that folder still has `pubspec.yaml`. Recents come from `recentProjectPaths` (absolute, last 8).
- Store `targetProjectPath` as an absolute path.
- Confirm is blocked until the folder is a Flutter project.

## Platform catalog

**Windows and Linux (Android-full):** show every non-iOS id, including AAB, APK, splits, collect, Play production and internal, Drive, Slack, report, quality extras, and power. If the project has no `android/` folder, still show those rows. Disable them with a reason.

**macOS (full):** show the Windows set plus `podInstall`, `buildIpa`, `collectIpa`, `distAppStore`. If the project has no `ios/` folder or App Store secrets are missing, still show those rows. Disable them with a reason.

Quality ids (`format`, `analyze`, `test`) are agent extras. Still optional and cacheable.

## Readiness

Blocked rows stay visible with a short reason. Do not run a blocked id, even if last-run `selected` listed it.

Layer A (project and secrets, filesystem plus JSON only):

- No project: project-dependent steps blocked.
- No `pubspec.yaml`: not a Flutter project.
- No `.git`: git steps blocked.
- No `android/`: Android build, collect, Play, Drive, Slack blocked.
- No `ios/`: iOS and App Store blocked (macOS only, still shown).
- Play: `playSaJsonPath` file exists and `playPackageName` is set.
- App Store: issuer, key id, and `.p8` path exist.
- Drive: `driveOauthJson` present.
- Slack: `slackWebhookUrl` present.
- Report: `gmailAddress` and `appPassword` in secrets, never in the picker page.
- WhatsApp: valid number in the picker (10 to 15 digits). Default form value is `+923096547269`.

Layer B (parent step):

- `collectAab` needs `buildAab`.
- `collectApk` needs `buildApk` or `buildSplits`.
- `collectIpa` needs `buildIpa`.
- Play needs `collectAab`.
- App Store needs `collectIpa`.
- Drive needs `collectApk`.
- Slack needs `collectApk` and `distDrive`.

If a dependency failed or was skipped at runtime, skip dependents the same way.

## Fallback (picker cannot open)

Use this only if `dart tool/pipeline_picker.dart` cannot start. Two `AskQuestion` rounds:

1. Project: last path (if any), this workspace if it has `pubspec.yaml`, or Other.
2. Steps: host-OS catalog only. Blocked ids stay listed as `[blocked: reason]`. Do not run a blocked id if the user still picks it.

Do not use chat checkboxes as the normal path.

## Cache, logs, secrets

Create `.fluship-agent/` as needed. Gitignores it.

**`.fluship-agent/pipeline-cache.json`** (the picker writes this on submit):

```json
{
  "selected": ["clean", "pubGet", "buildAab", "collectAab", "report"],
  "version": "1.0.0",
  "buildNumber": "1",
  "gitBranch": "master",
  "targetProjectPath": "/absolute/path/to/app",
  "recentProjectPaths": ["/absolute/path/to/app"],
  "preCommitMessage": "{version} cleanup",
  "postCommitMessage": "{version} release",
  "releaseNotes": "",
  "emailRecipient": "team@example.com",
  "playTrack": "production",
  "powerAction": null,
  "powerDelaySeconds": 10,
  "driveRecipients": [],
  "whatsappNumber": "+923096547269",
  "updatedAt": "2026-08-24T18:00:00.000Z"
}
```

`{version}` in commit messages is replaced with the run version.

**`.fluship-agent/secrets.json`** (ask once when a step needs it, then reuse):

```json
{
  "gmailAddress": "",
  "appPassword": "",
  "playSaJsonPath": "",
  "playPackageName": "",
  "appStoreIssuerId": "",
  "appStoreApiKeyId": "",
  "appStoreApiKeyPath": "",
  "driveOauthJson": "",
  "driveTokenJson": "",
  "driveFolderId": "",
  "slackWebhookUrl": ""
}
```

**`.fluship-agent/last-run.json`**: `logFilePath`, `outputDir`, `startedAt`, `success`.

**Run folder** (same as the app):

`{workspace}/outputs/{sanitizedProject}/v{version}/{buildNumber}/`

`logs.txt` lives there. Sanitize the project folder to lowercase `[a-z0-9_]` and strip other path characters from version and build number.

Log lines: timestamp, step id, command, exit code, output. On retry write `[retry N]`.

## Step catalog

Order: Version, Git before build, Prepare, Quality, Android, iOS, Git after build, Stores, Email, WhatsApp, After the run.

| id | Command / action | Notes |
| --- | --- | --- |
| `bumpVersion` | Set `pubspec.yaml` to `{version}+{buildNumber}` | Critical. Skip if version or build is empty. |
| `preCommit` | `git add . && git commit -m "{msg}"` | Fallback `{version} cleanup`. Fail on real git errors. |
| `prePull` | `git pull origin {branch}` | Fail on real git errors. |
| `clean` | `flutter clean` | Critical. |
| `pubGet` | `flutter pub get` | Critical. Mutex with `pubUpgrade`. |
| `pubUpgrade` | `flutter pub upgrade` | Critical. Mutex with `pubGet`. |
| `format` | `dart format .` | Agent extra. |
| `analyze` | `flutter analyze` | Agent extra. |
| `test` | `flutter test` | Agent extra. |
| `buildAab` | `flutter build aab --release` | Can run with APK/splits. |
| `collectAab` | Copy new `*.aab` from `build/app/outputs/bundle/release/` | Depends on `buildAab`. Only files from this run (5s tolerance). |
| `buildApk` | `flutter build apk --release` | Mutex with `buildSplits`. |
| `buildSplits` | `flutter build apk --split-per-abi` | Mutex with `buildApk`. |
| `collectApk` | Copy new `*.apk` from `build/app/outputs/flutter-apk/` | Depends on `buildApk` or `buildSplits`. |
| `podInstall` | `cd ios && pod install --repo-update` | macOS only. Recovery once: `pod deintegrate && pod repo update && pod install`. |
| `buildIpa` | `flutter build ipa` | macOS only. Depends on `podInstall` if that id was selected. |
| `collectIpa` | Copy new `*.ipa` from `build/ios/ipa/` | macOS only. Depends on `buildIpa`. |
| `postCommit` | `git add . && git commit -m "{msg}"` | Fallback `{version} release`. |
| `postPush` | `git push origin {branch}` | Never force-push. |
| `distPlayProduction` | Play upload (production) | Depends on `collectAab`. Mutex with `distPlayInternal`. Needs Play secrets. Optional `releaseNotes`. Skip if creds missing. Do not invent an uploader. Use the Fluship app or existing Play API tooling the user already has. |
| `distPlayInternal` | Play upload (internal) | Same as production, internal track. |
| `distAppStore` | `xcrun iTMSTransporter -m upload -assetFile {ipa} -apiKey {id} -apiIssuer {issuer} -apiKeyPath {p8} -v eXtreme` | macOS only. Depends on `collectIpa`. Skip if creds missing. |
| `distDrive` | Upload collected APKs to Drive | Depends on `collectApk`. Needs Drive OAuth files. Skip if creds missing. Do not invent an uploader. |
| `slackNotify` | POST webhook after Drive | Needs `slackWebhookUrl`. Skip if missing. |
| `report` | Email HTML report + attach `logs.txt` | Always run at the end if selected. See Email. |
| `whatsappShare` | PDF report plus APKs to WhatsApp | Optional. Dialog number defaults to `+923096547269`. Run `dart tool/whatsapp_share.dart` at the end if selected. Never hand-type the chat. Needs a valid number. |
| `openOutputs` | Windows `explorer {outputDir}`; macOS `open`; Linux `xdg-open` | |
| `powerShutdown` | After delay, shut down | Mutex with other power ids. Second confirm. Windows `shutdown /s /t {delay}`. macOS `sudo shutdown -h +{minutes}`. Linux `shutdown -h +{minutes}`. |
| `powerSleep` | After delay, sleep | Second confirm. Windows `rundll32.exe powrprof.dll,SetSuspendState 0,1,0`. macOS `pmset sleepnow`. Linux `systemctl suspend`. |
| `powerLock` | After delay, lock | Second confirm. Windows `rundll32.exe user32.dll,LockWorkStation`. macOS `pmset displaysleepnow`. Linux `loginctl lock-session`. |

Mutex pairs: `pubGet`/`pubUpgrade`, `buildApk`/`buildSplits`, `distPlayProduction`/`distPlayInternal`, power actions.

## Email (`report`)

If `report` is selected and Gmail secrets are missing, ask for `gmailAddress`, `appPassword`, and recipient, save secrets and `emailRecipient`, then send.

```bash
dart run tool/send_pipeline_report.dart --log {logFilePath} --app-name {name} --version {version} --build-number {buildNumber} --success true --elapsed 2m10s --platforms Android --steps Clean:ok:1.2s,BuildAab:fail:3m4s
```

`--recipient` optional (falls back to cache). `--secrets` and `--cache` optional. Do not pass the password on the command line.

Subject style: `✓ {app} v{version}+{build} - Build Report` or `✗` on failure.

## Repo map

- `lib/features/config` Config toggles and `ConfigBloc`
- `lib/features/pipeline` `PipelineBloc` and run UI
- `lib/features/console` live shell sessions
- `lib/features/settings` profiles, paths, credentials, themes
- `lib/features/file_manager` and `lib/features/process_manager`
- `lib/services/pipeline` resolver, artifacts, paths (`ConfigPipelineResolver`, `step_resolvers.dart`)
- `lib/services/distribution` Play, App Store, Drive, email, Slack
- `lib/di/locator.dart` GetIt
- `lib/shared/models` config models
- `lib/shared/widgets` `AppCard`, `AppText`, `AppTextField`, `SwitchLabel`
- `lib/shared/extensions/widget_extensions.dart` UI helpers
- `tool/pipeline_warmup.dart` Ask for host permissions at the start
- `tool/pipeline_picker.dart` Agent pipeline picker
- `tool/pipeline_progress.dart` Live NOW / DONE / WAIT board for chat
- `tool/whatsapp_share.dart` WhatsApp PDF and APK share
- `tool/pipeline_cleanup.dart` Tracked and orphan process cleanup
- `test/` mirrors features and services

## Add a pipeline step

1. Field on the model in `lib/shared/models`.
2. Toggle on the matching Config section.
3. Id on `PipelineStepId` if it participates in skip/depends.
4. Resolver in `lib/services/pipeline/resolver/step_resolvers.dart` in the same order as `ConfigPipelineResolver`.
5. Tests under `test/shared/pipeline/` or `test/features/pipeline/`.
6. Add the id to the catalog in this file and in `tool/pipeline_picker/catalog.dart`.

## Dart conventions

- UI padding and layout: `.padAll`, `.padSym`, `.padOnly`, `.expanded()`, `.flexible()`, `.center()` from `widget_extensions.dart`.
- Dart 3 shorthands already used in this repo (enum dots, `.w600`).
- `flutter_bloc` + `get_it` + `equatable`. Features own blocs. Pipeline execution lives in services.
- Prefer `AppCard`, `AppText`, `SwitchLabel` over raw Material.
- `prefer_const_constructors` is on. `prefer_single_quotes` is off. Keep existing quote style.
- Clean, DRY, SOLID. No drive-by refactors.

## Verify

```bash
dart format .
flutter analyze
flutter test
```

Agent picker tests:

```bash
dart tool/pipeline_picker/run_all_tests.dart
```

Dev run: `flutter pub get` then `flutter run`.

## Safety

- No `git push --force` to main/master.
- No commit unless `preCommit` / `postCommit` was checked or the user explicitly asked.
- No store upload or email without the matching id and credentials.
- Never run power actions without the id plus a second confirm.
- Never commit secrets, cache, or `outputs/`.
