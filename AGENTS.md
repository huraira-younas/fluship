# Fluship Agent Guide

Reference this file (`@AGENTS.md`) before any Fluship work: run pipeline, ship, build, or change this repo.

Fluship is a Flutter GUI release cockpit. There is no `fluship run` CLI. When asked to run a pipeline, execute the same steps the app would, in the target Flutter project, using the protocol below.

## Hard rules

- Every catalog step is optional. Never invent a default set on a first run. Never hide a Fluship step.
- Never start commands until the user answers checkboxes. Use `AskQuestion` with `allow_multiple: true`. If that tool is missing, print the same checklist and wait.
- If the user already named steps, still show the full checkbox list. Do not silently add extras.
- After they pick, write `.fluship-agent/pipeline-cache.json` immediately. Next session those picks are the defaults.
- Logs are mandatory every run (not a checkbox). Create the run folder and `logs.txt` before the first step.
- Do not commit, push, upload stores, email, or run power actions unless those exact ids were selected. Power needs a second confirm.
- Do not swallow git failures. The GUI uses `|| true`. You must not.
- Critical ids abort later steps: `bumpVersion`, `clean`, `pubGet`, `pubUpgrade`. Then offer fix and continue.
- After any Dart edit, run `dart format .` and `flutter analyze`.
- Never commit `.fluship-agent/secrets.json`. Never print the app password.
- No em-dashes in comments, markdown, or user-facing text you write in this repo.

## Protocol

1. Read `.fluship-agent/pipeline-cache.json` if it exists.
2. If cache exists, ask: **Reuse last selection** or **Customize**. Reuse shows the saved id list, then proceeds. Customize shows every id, with last-run ids marked `[saved]`.
3. If no cache, show every id. Nothing is pre-picked.
4. If a mutex pair is both picked, re-ask that pair.
5. If `bumpVersion` or any git step is selected and version, build number, or branch is missing, ask and reuse cache values when present. Default branch is `master`.
6. Write cache. Then create logs.
7. Run only selected steps in catalog order. Append every command, stdout, stderr, status, and retry to `logs.txt`.
8. On failure: diagnose from the log, fix the real cause, `dart format .` then `flutter analyze` if Dart changed, retry that step. Max 3 retries. Then continue or abort per critical rules. You may resume from the failed step.
9. If `report` is selected, send the email at the end even when earlier steps failed.
10. Summarize: selected ids, each status, log path, email result.

Target project defaults to this repo. Another Flutter path is allowed and saved as `targetProjectPath`.

## Cache, logs, secrets

Create `.fluship-agent/` as needed. Gitignores it.

**`.fluship-agent/pipeline-cache.json`** (write after every selection):

```json
{
  "selected": ["clean", "pubGet", "buildAab", "collectAab", "report"],
  "version": "1.0.0",
  "buildNumber": "1",
  "gitBranch": "master",
  "targetProjectPath": ".",
  "preCommitMessage": "{version} cleanup",
  "postCommitMessage": "{version} release",
  "releaseNotes": "",
  "emailRecipient": "team@example.com",
  "playTrack": "production",
  "powerAction": null,
  "powerDelaySeconds": 10,
  "driveRecipients": [],
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

## AskQuestion ids

Offer every id below. On macOS include iOS ids. Off macOS omit `podInstall`, `buildIpa`, `collectIpa`, `distAppStore` or mark them unavailable.

Quality ids (`format`, `analyze`, `test`) are agent extras. Still optional and cacheable.

## Step catalog

Order: App Info, Pre-Git, Common, Android, iOS, Post-Git, Distribution, Post-Build, Report.

| id | Command / action | Notes |
| --- | --- | --- |
| `bumpVersion` | Set `pubspec.yaml` to `{version}+{buildNumber}` | Critical. Skip if version or build is empty. |
| `preCommit` | `git add . && git commit -m "{msg}"` | Fallback `{version} cleanup`. Fail on real git errors. |
| `prePull` | `git pull origin {branch}` | Fail on real git errors. |
| `clean` | `flutter clean` | Critical. |
| `pubGet` | `flutter pub get` | Critical. Mutex with `pubUpgrade`. |
| `pubUpgrade` | `flutter pub upgrade` | Critical. Mutex with `pubGet`. |
| `buildAab` | `flutter build aab --release` | Can run with APK/splits. |
| `collectAab` | Copy new `*.aab` from `build/app/outputs/bundle/release/` | Depends on `buildAab`. Only files from this run (5s tolerance). |
| `buildApk` | `flutter build apk --release` | Mutex with `buildSplits`. |
| `buildSplits` | `flutter build apk --split-per-abi` | Mutex with `buildApk`. |
| `collectApk` | Copy new `*.apk` from `build/app/outputs/flutter-apk/` | Depends on `buildApk` or `buildSplits`. |
| `podInstall` | `cd ios && pod install --repo-update` | macOS. Recovery once: `pod deintegrate && pod repo update && pod install`. |
| `buildIpa` | `flutter build ipa` | macOS. Depends on `podInstall` if that id was selected. |
| `collectIpa` | Copy new `*.ipa` from `build/ios/ipa/` | Depends on `buildIpa`. |
| `postCommit` | `git add . && git commit -m "{msg}"` | Fallback `{version} release`. |
| `postPush` | `git push origin {branch}` | Never force-push. |
| `distPlayProduction` | Play upload (production) | Depends on `collectAab`. Mutex with `distPlayInternal`. Needs `playSaJsonPath` + `playPackageName`. Optional `releaseNotes`. Skip if creds missing. Do not invent an uploader. Use the Fluship app or existing Play API tooling the user already has. |
| `distPlayInternal` | Play upload (internal) | Same as production, internal track. |
| `distAppStore` | `xcrun iTMSTransporter -m upload -assetFile {ipa} -apiKey {id} -apiIssuer {issuer} -apiKeyPath {p8} -v eXtreme` | macOS. Depends on `collectIpa`. Skip if creds missing. |
| `distDrive` | Upload collected APKs to Drive | Depends on `collectApk`. Needs Drive OAuth files. Skip if creds missing. Do not invent an uploader. |
| `slackNotify` | POST webhook after Drive | Attached to Drive in the app. Needs `slackWebhookUrl`. Skip if missing. |
| `report` | Email HTML report + attach `logs.txt` | Always run at the end if selected. See Email. |
| `openOutputs` | Windows `explorer {outputDir}`; macOS `open`; Linux `xdg-open` | |
| `powerShutdown` | After delay, shut down | Mutex with other power ids. Second confirm. Windows `shutdown /s /t {delay}`. macOS `sudo shutdown -h +{minutes}`. Linux `shutdown -h +{minutes}`. |
| `powerSleep` | After delay, sleep | Second confirm. Windows `rundll32.exe powrprof.dll,SetSuspendState 0,1,0`. macOS `pmset sleepnow`. Linux `systemctl suspend`. |
| `powerLock` | After delay, lock | Second confirm. Windows `rundll32.exe user32.dll,LockWorkStation`. macOS `pmset displaysleepnow`. Linux `loginctl lock-session`. |
| `format` | `dart format .` | Agent extra. |
| `analyze` | `flutter analyze` | Agent extra. |
| `test` | `flutter test` | Agent extra. |

Working directory for Flutter and git commands is `targetProjectPath`.

If a dependency failed or was skipped, skip dependents (`collectAab` needs `buildAab`, Play needs `collectAab`, TestFlight needs `collectIpa`, Drive needs `collectApk`).

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
- `test/` mirrors features and services

## Add a pipeline step

1. Field on the model in `lib/shared/models`.
2. Toggle on the matching Config section.
3. Id on `PipelineStepId` if it participates in skip/depends.
4. Resolver in `lib/services/pipeline/resolver/step_resolvers.dart` in the same order as `ConfigPipelineResolver`.
5. Tests under `test/shared/pipeline/` or `test/features/pipeline/`.
6. Add the id to the catalog in this file.

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

Dev run: `flutter pub get` then `flutter run`.

## Safety

- No `git push --force` to main/master.
- No commit unless `preCommit` / `postCommit` was checked or the user explicitly asked.
- No store upload or email without the matching id and credentials.
- Never run power actions without the id plus a second confirm.
- Never commit secrets, cache, or `outputs/`.
