# Fluship Agent Guide

Run this file when the user says run pipeline, ship, or build AAB / APK / IPA.

This workspace holds the picker, the cache, and `outputs/`. The Flutter app is `targetProjectPath` from the cache. Never edit `lib/` during a run.

## Execution mode

A run is mechanical. Work through the steps in order at full speed.

Do not think between jobs. No planning, no options, no re-reading this file, no asking what comes next. Reasoning is for one case only: a command failed, or a needed value is missing.

Every job is the same loop:

1. Run the command. Background anything slow, then poll in 5 second checks (`block_until_ms: 5000`) until the footer shows `exit_code`. Never guess a duration.
2. Run `pipeline_progress.dart`.
3. Paste its stdout into your reply in a fenced code block. Running it is not printing the board: tool output sits in a collapsed block, and your reasoning is never shown at all.
4. Start the next job in the same turn.

Chat holds the board and nothing else, apart from one short line when something genuinely needs saying.

## Rules

- Every shell command in a run uses full host permissions (`required_permissions: ["all"]`).
- Run only the ids the picker returned, in catalog order. Never add or default an id.
- One board per job, ok, fail, or skip. Never batch them. A long job gets one at start and one at end.
- Logs are mandatory. Create the run folder, `logs.txt`, and `progress.json` before the first job.
- Critical ids abort the rest of the run: `bumpVersion`, `clean`, `pubGet`, `pubUpgrade`.
- Never commit `.fluship-agent/secrets.json` or `outputs/`. Never print the app password. No em-dashes.

## Run

1. Warm up host permissions. Paste the board. Exit 4 means Accessibility is missing: wait, then run it again.

```bash
dart tool/pipeline_warmup.dart
```

2. Start the picker in the background. Never `flutter run` or `dart run` it.

```bash
dart tool/pipeline_picker.dart
```

Poll it in 5 second checks; the user may sit on the form for a while.

Read `Pipeline picker:` and `open-in:` from stdout or `.fluship-agent/picker-open.json`. The picker already opened its own tab, in the Cursor panel (`cursor-ide`) or Chrome (`chrome`). Do not open a second one.

Exit 0 submit. Exit 2 cancel. Exit 3 timeout. Anything else is an error. On anything but 0, run cleanup and stop.

Never close the picker tab. Chrome closes itself, a `cursor-ide` tab is the user's to close, and a leftover tab never blocks the run. Do not use your browser tool on it, and never make the page close itself: `window.close()` in the Cursor browser takes the whole window down.

3. Read `.fluship-agent/pipeline-cache.json`, then prepare the host.

```bash
dart tool/pipeline_cleanup.dart --prepare --project {targetProjectPath}
```

4. Create `outputs/{sanitizedProject}/v{version}/{buildNumber}/` and `logs.txt`. Sanitize the project folder to lowercase `[a-z0-9_]`. Write `.fluship-agent/last-run.json` with `logFilePath`, `outputDir`, `startedAt`, `success`.

5. Print the board before the first job and after every job. Paste the stdout as-is, never edited.

```bash
dart tool/pipeline_progress.dart --selected id1,id2 --current id2 --done id1 --results id1=ok --times id1=0.3s --app NAME --version VER --build NUM --progress .fluship-agent/progress.json --log {logFilePath}
```

6. If `whatsappShare` is selected and the cache number is valid, start the heartbeat once logs exist, then track its PID. It sends the same board, narrower, every 3 minutes while the current job has run at least 3 minutes. Text only, and a failed ping never fails the build.

```bash
dart tool/pipeline_heartbeat.dart --progress .fluship-agent/progress.json --number {whatsappNumber} --interval-seconds 180
```

7. Run the selected ids back to back. Skip iOS ids off macOS. For a mutex pair, keep the first in catalog order and skip the other. Skip an id whose parent failed or was skipped. Append every command, output, exit code, and `[retry N]` to `logs.txt`. After each build PID: `dart tool/pipeline_cleanup.dart --track {pid} --project {targetProjectPath}`.

Ask only when something is genuinely missing: version, build, or branch for `bumpVersion` and git ids (default branch `master`); secrets for a dist id or `report`; a second confirm for a power id. Secrets normally arrive from the picker Setup panel, so only ask when a selected id still has none. Save answered secrets to `.fluship-agent/secrets.json`. If the user cancels a secrets ask, skip that id only.

8. On failure, the one place to think: read the error, fix the real cause, retry that id, max 3 times, then resume the loop. For any iOS pod error, delete `ios/Podfile.lock` first. After 3 failures, abort if the id is critical, otherwise continue.

9. `report` and `whatsappShare` run last, in that order, even when earlier jobs failed. Set the board current id to `whatsappShare` before the file send so the heartbeat does not collide. Never type into the WhatsApp chat.

```bash
dart tool/whatsapp_share.dart --log {logFilePath} --output-dir {outputDir} --project {targetProjectPath} --number {whatsappNumber} --app-name {name} --version {version} --build-number {buildNumber} --success true --steps Clean:ok:1.2s,BuildAab:ok:3m4s
```

Exit 2: run the warmup, then retry this command once. Never send the text without the PDF.

10. Always cleanup last, on success, failure, cancel, timeout, or stop. Add `--close-picker` when stopping. Cleanup marks `progress.json` idle and kills the heartbeat PID.

```bash
dart tool/pipeline_cleanup.dart --project {targetProjectPath}
```

11. Summarize: selected ids and their status, log path, email result, WhatsApp result, final board.

If the picker cannot start, fall back to exactly two `AskQuestion` rounds: project, then the host-OS catalog with blocked ids listed.

## Catalog

Windows and Linux run every non-iOS id. macOS runs all of them.

Parents: `collectAab` needs `buildAab`. `collectApk` needs `buildApk` or `buildSplits`. `collectIpa` needs `buildIpa`. Play needs `collectAab`. App Store needs `collectIpa`. Drive needs `collectApk`. Slack needs `collectApk` and `distDrive`.

Mutex pairs: `pubGet`/`pubUpgrade`, `buildApk`/`buildSplits`, `distPlayProduction`/`distPlayInternal`, and the power ids.

| id | Action |
| --- | --- |
| `bumpVersion` | Set `pubspec.yaml` to `{version}+{buildNumber}`. Critical. |
| `preCommit` | `git add . && git commit -m "{msg}"`. Fallback `{version} cleanup`. Nothing to commit is ok. |
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
| `podInstall` | `cd ios && pod install --repo-update`. macOS. |
| `buildIpa` | `flutter build ipa`. macOS. |
| `collectIpa` | Copy this run's `*.ipa` from `build/ios/ipa/`. macOS. |
| `postCommit` | `git add . && git commit -m "{msg}"`. Fallback `{version} release`. Nothing to commit is ok. |
| `postPush` | `git push origin {branch}`. Never force-push. |
| `distPlayProduction` | `dart run tool/dist_play.dart --aab {aab} --track production --progress .fluship-agent/progress.json` |
| `distPlayInternal` | Same as production with `--track internal`. |
| `distAppStore` | `dart run tool/dist_app_store.dart --ipa {ipa} --progress .fluship-agent/progress.json`. macOS. |
| `distDrive` | `dart run tool/dist_drive.dart --output-dir {outputDir} --progress .fluship-agent/progress.json`. Writes `.fluship-agent/last-drive.json`. |
| `slackNotify` | `dart run tool/slack_notify.dart --link {driveLink} --app-name {name} --version {ver} --build-number {num}` |
| `report` | `dart run tool/send_pipeline_report.dart --log {logFilePath} --app-name {name} --version {version} --build-number {buildNumber} --success true --elapsed 2m10s --platforms Android --steps Clean:ok:1.2s`. Never pass the password on the command line. |
| `whatsappShare` | `dart tool/whatsapp_share.dart` (see step 9). Number is 10 to 15 digits. |
| `openOutputs` | Windows `explorer`; macOS `open`; Linux `xdg-open`. |
| `powerShutdown` | Windows `shutdown /s /t {delay}`; macOS `sudo shutdown -h +{minutes}`; Linux `shutdown -h +{minutes}`. |
| `powerSleep` | Windows `rundll32.exe powrprof.dll,SetSuspendState 0,1,0`; macOS `pmset sleepnow`; Linux `systemctl suspend`. |
| `powerLock` | Windows `rundll32.exe user32.dll,LockWorkStation`; macOS `pmset displaysleepnow`; Linux `loginctl lock-session`. |

## Cache

`.fluship-agent/` is gitignored.

`pipeline-cache.json` (written by the picker): `selected`, `version`, `buildNumber`, `gitBranch`, `targetProjectPath`, `recentProjectPaths`, commit messages (`{version}` replaced at run time), `releaseNotes`, `emailRecipient`, `playTrack`, `powerAction`, `powerDelaySeconds`, `driveRecipients`, `whatsappNumber`.

`secrets.json` (filled in the picker Setup panel, or asked once): `gmailAddress`, `appPassword`, `playSaJsonPath`, `playPackageName`, `appStoreIssuerId`, `appStoreApiKeyId`, `appStoreApiKeyPath`, `driveOauthJson`, `driveTokenJson`, `driveFolderId`, `slackWebhookUrl`. The panel reads every key back except `appPassword`, which stays write-only.

## Working on this repo

Only when the user asks for a change to Fluship itself, not during a pipeline run.

- After Dart edits: `dart format .` and `flutter analyze`.
- Pipeline tests: `dart tool/pipeline_picker/tests/run_all.dart`.
