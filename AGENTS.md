# Fluship Agent Guide

Follow this file for run pipeline, ship, or build AAB / APK / IPA. Do not change `lib/` for a pipeline run. Picker, cache, and `outputs/` live in this workspace. Flutter and git commands use `targetProjectPath`.

## Rules

- Every catalog step is optional. Never invent a default set.
- Show is not select. First run checks nothing. Never hide a host-OS step. Windows and Linux omit iOS ids. macOS shows iOS ids even when blocked.
- Do not start jobs before the picker exits 0. Do not add extra ids the user did not submit.
- Ask for host permissions first. Do not start a long step while Allow is pending. Every shell command in the run uses full host permissions (`required_permissions: ["all"]`).
- Logs are mandatory. Create the run folder and `logs.txt` before the first job. Also write `.fluship-agent/progress.json` before the first job.
- After every job (ok, fail, skip), run the board command and paste that stdout in chat before the next job. The user must see NOW / DONE / WAIT / FAIL / SKIP. Never hide the board in tool output only. Never batch. Never wait until the end. A long job gets a board when it starts (NOW) and again when it ends. Update `progress.json` with the same board command.
- Do not commit, push, upload stores, email, or run power unless that id was selected. Power needs a second confirm after the picker.
- Do not swallow git failures. Critical ids abort later jobs: `bumpVersion`, `clean`, `pubGet`, `pubUpgrade`. Then offer fix and continue.
- After Dart edits in this repo: `dart format .` and `flutter analyze`.
- Never commit `.fluship-agent/secrets.json` or `outputs/`. Never print the app password. No em-dashes.

## Run

0. Stay until the picker is on screen.

```bash
dart tool/pipeline_warmup.dart
```

Paste the warmup board. Exit 4: wait for Accessibility, run warmup again. Do not launch the picker while a prompt is waiting.

1. Start the picker in the background. Do not paste the catalog. Do not use `flutter` or `dart run`.

```bash
dart tool/pipeline_picker.dart
```

Read `Pipeline picker:` and `open-in:` from stdout or `.fluship-agent/picker-open.json`.

- `cursor-ide`: the picker already opened one IDE tab. Do not open another. Do not open Chrome.
- `chrome`: the picker already opened Chrome. Do not open the IDE panel.

Exit 0 submit. Exit 2 cancel. Exit 3 timeout. Anything else is an error. On cancel, timeout, or error: cleanup and stop.

2. Read `.fluship-agent/pipeline-cache.json`. `targetProjectPath` is the Flutter app.

```bash
dart tool/pipeline_cleanup.dart --prepare --project {targetProjectPath}
```

3. Create `{workspace}/outputs/{sanitizedProject}/v{version}/{buildNumber}/` and `logs.txt`. Write `.fluship-agent/last-run.json` (`logFilePath`, `outputDir`, `startedAt`, `success`). Sanitize the project folder to lowercase `[a-z0-9_]`. Write `.fluship-agent/progress.json` with the first board command.

4. Print the board before the first job, and again after every job:

```bash
dart tool/pipeline_progress.dart --selected id1,id2 --current id2 --done id1 --results id1=ok --times id1=0.3s --app NAME --version VER --build NUM --progress .fluship-agent/progress.json --log {logFilePath}
```

Paste stdout as-is in the chat message. Do not start the next id until that board is in chat. After each build PID: `dart tool/pipeline_cleanup.dart --track {pid} --project {targetProjectPath}`.

If `whatsappShare` is selected and the cache number is valid, start the heartbeat after logs exist, then track its PID:

```bash
dart tool/pipeline_heartbeat.dart --progress .fluship-agent/progress.json --number {whatsappNumber} --interval-seconds 120
```

It sends a WhatsApp text ping every 2 minutes while the current job has been running at least 2 minutes. Text only. No files. Do not type the chat. A failed ping does not fail the build. Pause pings while `whatsappShare` is the current id. Cleanup always stops this PID.

5. Run only selected ids that are still enabled on this host OS, in catalog order. Ignore iOS ids on Windows and Linux. Mutex pair: keep the first in catalog order, skip the other.

6. If `bumpVersion` or a git step is selected and version, build, or branch is missing, ask. Reuse cache when present. Default branch is `master`.

7. Append every command, output, exit, and `[retry N]` to `logs.txt`.

8. On failure: fix the real cause, then retry that id (max 3). If Dart in this repo changed, format and analyze first. For `podInstall` (or any iOS pod error): delete `ios/Podfile.lock`, then retry. After 3 failures, continue or abort per critical rules.

9. If a dist id is selected and its secrets are missing, ask once, save them to `.fluship-agent/secrets.json`, then run. If the user cancels the ask, skip that id only.

10. If `report` is selected, send it at the end even when earlier jobs failed.

11. If `whatsappShare` is selected, run it last after logs exist, even when earlier jobs failed. Set the board current id to `whatsappShare` before the file send so heartbeat does not collide. Never type the WhatsApp chat.

```bash
dart tool/whatsapp_share.dart --log {logFilePath} --output-dir {outputDir} --project {targetProjectPath} --number {whatsappNumber} --app-name {name} --version {version} --build-number {buildNumber} --success true --steps Clean:ok:1.2s,BuildAab:ok:3m4s
```

Exit 2: warmup, then retry that command once. Do not send text without the PDF.

12. If a power id is selected, ask one second confirm.

13. Always cleanup last (success, fail, cancel, timeout, close, stop):

```bash
dart tool/pipeline_cleanup.dart --project {targetProjectPath}
```

On close/stop also pass `--close-picker`. Cleanup marks `progress.json` idle and kills the heartbeat PID.

14. Summarize: selected ids, each status, log path, email result, WhatsApp result, final board.

If the picker cannot start, two `AskQuestion` rounds only: project, then host-OS catalog with blocked ids listed. Do not use chat checkboxes as the normal path.

## Catalog

Windows and Linux: every non-iOS id. macOS: that set plus iOS ids. Blocked rows stay visible. Do not run a blocked id.

Parents: `collectAab` needs `buildAab`. `collectApk` needs `buildApk` or `buildSplits`. `collectIpa` needs `buildIpa`. Play needs `collectAab`. App Store needs `collectIpa`. Drive needs `collectApk`. Slack needs `collectApk` and `distDrive`. If a parent failed or was skipped, skip dependents.

Mutex: `pubGet`/`pubUpgrade`, `buildApk`/`buildSplits`, `distPlayProduction`/`distPlayInternal`, power ids.

| id | Action |
| --- | --- |
| `bumpVersion` | Set `pubspec.yaml` to `{version}+{buildNumber}`. Critical. |
| `preCommit` | `git add . && git commit -m "{msg}"`. Fallback `{version} cleanup`. If git says nothing to commit, mark ok. |
| `prePull` | `git pull origin {branch}`. |
| `clean` | `flutter clean`. Critical. |
| `pubGet` | `flutter pub get`. Critical. |
| `pubUpgrade` | `flutter pub upgrade`. Critical. |
| `format` | `dart format .` |
| `analyze` | `flutter analyze` |
| `test` | `flutter test` |
| `buildAab` | `flutter build aab --release` |
| `collectAab` | Copy this run's `*.aab` from `build/app/outputs/bundle/release/` (5s tolerance). |
| `buildApk` | `flutter build apk --release` |
| `buildSplits` | `flutter build apk --split-per-abi` |
| `collectApk` | Copy this run's `*.apk` from `build/app/outputs/flutter-apk/`. |
| `podInstall` | `cd ios && pod install --repo-update`. macOS. On error: delete `ios/Podfile.lock` and retry. |
| `buildIpa` | `flutter build ipa`. macOS. |
| `collectIpa` | Copy this run's `*.ipa` from `build/ios/ipa/`. macOS. |
| `postCommit` | `git add . && git commit -m "{msg}"`. Fallback `{version} release`. If git says nothing to commit, mark ok. |
| `postPush` | `git push origin {branch}`. Never force-push. |
| `distPlayProduction` | `dart run tool/dist_play.dart --aab {aab} --track production --progress .fluship-agent/progress.json`. Ask once for Play secrets if missing. |
| `distPlayInternal` | `dart run tool/dist_play.dart --aab {aab} --track internal --progress .fluship-agent/progress.json`. Same secrets as production. |
| `distAppStore` | `dart run tool/dist_app_store.dart --ipa {ipa} --progress .fluship-agent/progress.json`. macOS. Ask once for App Store secrets if missing. |
| `distDrive` | `dart run tool/dist_drive.dart --output-dir {outputDir} --progress .fluship-agent/progress.json`. Ask once for Drive secrets if missing. Writes `.fluship-agent/last-drive.json`. |
| `slackNotify` | `dart run tool/slack_notify.dart --link {driveLink} --app-name {name} --version {ver} --build-number {num}`. Ask once for `slackWebhookUrl` if missing. |
| `report` | Email HTML report and `logs.txt`. Ask for Gmail secrets once if missing, save them, then: `dart run tool/send_pipeline_report.dart --log {logFilePath} --app-name {name} --version {version} --build-number {buildNumber} --success true --elapsed 2m10s --platforms Android --steps Clean:ok:1.2s`. Do not pass the password on the command line. |
| `whatsappShare` | `dart tool/whatsapp_share.dart` (see Run). Valid number, 10 to 15 digits. Form default `+923096547269`. |
| `openOutputs` | Windows `explorer`; macOS `open`; Linux `xdg-open`. |
| `powerShutdown` | After delay. Windows `shutdown /s /t {delay}`. macOS `sudo shutdown -h +{minutes}`. Linux `shutdown -h +{minutes}`. |
| `powerSleep` | Windows `rundll32.exe powrprof.dll,SetSuspendState 0,1,0`. macOS `pmset sleepnow`. Linux `systemctl suspend`. |
| `powerLock` | Windows `rundll32.exe user32.dll,LockWorkStation`. macOS `pmset displaysleepnow`. Linux `loginctl lock-session`. |

## Cache

`.fluship-agent/` is gitignored. The picker writes `pipeline-cache.json`: `selected`, `version`, `buildNumber`, `gitBranch`, `targetProjectPath` (absolute), `recentProjectPaths` (last 8), commit messages (`{version}` replaced at run time), `releaseNotes`, `emailRecipient`, `playTrack`, `powerAction`, `powerDelaySeconds`, `driveRecipients`, `whatsappNumber`.

`secrets.json` (ask once when a step needs it): `gmailAddress`, `appPassword`, `playSaJsonPath`, `playPackageName`, `appStoreIssuerId`, `appStoreApiKeyId`, `appStoreApiKeyPath`, `driveOauthJson`, `driveTokenJson`, `driveFolderId`, `slackWebhookUrl`. Never put secrets in the picker page.

Confirm is blocked until `targetProjectPath` is a Flutter project.

## Tools

- `tool/pipeline_warmup.dart`
- `tool/pipeline_picker.dart`
- `tool/pipeline_progress.dart`
- `tool/pipeline_heartbeat.dart`
- `tool/pipeline_report.py`
- `tool/whatsapp_share.dart` (calls `tool/whatsapp_send.py`)
- `tool/pipeline_cleanup.dart`
- `tool/send_pipeline_report.dart`
- `tool/dist_play.dart`
- `tool/dist_drive.dart`
- `tool/dist_app_store.dart`
- `tool/slack_notify.dart`

Pipeline tests: `dart tool/pipeline_picker/tests/run_all.dart`.
