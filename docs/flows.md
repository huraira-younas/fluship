# Flows

## Setup

1. Settings sets the target Flutter project path and the Fluship workspace path.
2. Settings stores optional credentials: Google Play service account, App Store Connect API key, Google Drive OAuth client, Gmail app password, and report recipients.
3. Config enables stages and sets version, build number, and git branch.
4. A distribution toggle stays off until the credentials for that channel exist.

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

Play Store depends on a collected AAB. App Store depends on a collected IPA. Drive depends on a collected APK. The report has no artifact dependency and can still be sent after a failed run.

Critical steps stop the run. Cancel sets a flag and closes the console session. `FilePipelineLogWriter` writes the log into the Fluship workspace.

## What this app does not do

Fluship does not install or run itself on Android or iOS. Android and iOS in the pipeline are the target project. Do not delete those stages when changing Fluship's own platforms.
