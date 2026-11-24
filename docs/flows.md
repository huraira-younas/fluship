# Flows

## Setup

1. Settings sets the target Flutter project path and the Fluship workspace path.
2. Settings stores optional credentials: Google Play service account, App Store Connect API key, Google Drive OAuth client, Gmail app password, report recipients, and a WhatsApp agent API key.
3. Config enables stages and sets version, build number, and git branch.
4. A distribution toggle stays off until the credentials for that channel exist.

### WhatsApp agent

1. In WhatsApp, open Settings, then Agents, and create an agent. Open the agent chat, then Chat info, and copy the API key.
2. Paste the key in Settings under WhatsApp.
3. Send any message to the agent from the phone.
4. Press Connect. Fluship reads that message to learn the chat id, then "Send test message" confirms the link.

Changing the key clears the chat id, so Connect has to be pressed again.

Profiles are saved in `SharedPrefs` through `ProjectProfilesStore`. `ConfigBloc` loads the active profile at startup.

## Run pipeline

The runner panel dispatches `RunPipeline`.

1. `PipelineBloc` ignores the event if a run is already active.
2. It persists the active profile.
3. It refuses an empty project root or an empty Fluship workspace and emits a failure. No shell session starts.
4. It opens a console session through `PipelineConsolePort`.
5. `ConfigPipelineResolver.resolve` builds the step list from the current `ConfigState`.

Disabled stages resolve to an empty list and do not run.

## Step order

Owned by `ConfigPipelineResolver`. Add a stage there and in Config. Do not insert steps inside the bloc loop.

1. App info: bump `pubspec.yaml` version and build number when both fields are set.
2. Pre-git: optional commit, then optional pull.
3. Common commands: optional `flutter clean`, then either `flutter pub get` or `flutter pub upgrade`.
4. Android build and artifact copy (AAB, APK, or split APK) when the Android stage is enabled.
5. iOS build and artifact copy when the iOS stage is enabled. The target build runs on macOS.
6. Post-git: optional commit, then optional push.
7. Distribution: Play Store, App Store, Google Drive, for the channels that are enabled and have credentials.
8. Post-build commands.
9. Build report email.
10. WhatsApp summary: a text summary of every step, the Drive link when Drive uploaded in this run, and the pipeline log as `logs.txt`.

Play Store depends on a collected AAB. App Store depends on a collected IPA. Drive depends on a collected APK. The report and the WhatsApp summary have no artifact dependency and are still sent after a failed run.

Critical steps stop the run. `FilePipelineLogWriter` writes the log into the Fluship workspace.

## Cancel

Cancel ends the running command: the pipeline shell and every process it started are stopped. The steps that had not run are marked skipped, and the report and WhatsApp steps do not run.

An upload or email step cannot be interrupted. The panel shows "Cancelling…" until that step returns, and Run is ignored until then.

The next Run always starts from the first step in a new shell. It does not continue the cancelled run.

## What this app does not do

Fluship does not install or run itself on Android or iOS. Android and iOS in the pipeline are the target project. Do not delete those stages when changing Fluship's own platforms.
