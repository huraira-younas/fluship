/// Stable identifiers used to link a step to the steps that depend on it.
///
/// Skipping a failed or removed step cascades through these ids, so a build
/// that never produced an artifact can never be followed by a collect or an
/// upload of whatever the previous run left behind.
enum PipelineStepId {
  bumpVersion,
  pubUpgrade,
  preCommit,
  prePull,
  clean,
  pubGet,

  collectAab,
  collectApk,
  buildAab,
  buildApk,

  podInstall,
  collectIpa,
  buildIpa,

  postCommit,
  postPush,

  distAppStore,
  distDrive,
  distPlay,
  report,

  openOutputs,
  power,
}
