const reasonSelectProject = 'Select a Flutter project first.';
const reasonNoPubspec =
    'This folder is not a Flutter project (pubspec.yaml missing).';
const reasonNoGit =
    'This project has no .git folder. These steps enable after you initialize git.';
const reasonNoAndroid =
    'This project has no android/ folder. These steps enable after you add the Android platform.';
const reasonNoIos =
    'This project has no ios/ folder. These steps enable after you add the iOS platform.';
const reasonPlaySecrets =
    'Add the package name and service account JSON in Setup above.';
const reasonAppStoreSecrets =
    'Add the App Store issuer id, key id, and .p8 path in Setup above.';
const reasonDriveSecrets = 'Add the Drive OAuth client JSON in Setup above.';
const reasonSlackSecrets = 'Add the Slack web request URL in Setup above.';
const reasonReportSecrets =
    'Add the Gmail address and app password in Setup above.';
const reasonNeedBuildAab = 'Enable when you select buildAab.';
const reasonNeedApkBuild = 'Enable when you select buildApk or buildSplits.';
const reasonNeedBuildIpa = 'Enable when you select buildIpa.';
const reasonNeedCollectAab = 'Enable when you select collectAab.';
const reasonNeedCollectIpa = 'Enable when you select collectIpa.';
const reasonNeedCollectApk = 'Enable when you select collectApk.';
const reasonNeedDriveAndApk =
    'Enable when you select collectApk and distDrive.';
const reasonInvalidProject = 'Choose a folder that contains pubspec.yaml.';
const reasonWhatsAppNumber = 'Enter a valid WhatsApp number.';

const catalogUserFacingStrings = <String>[
  reasonSelectProject,
  reasonNoPubspec,
  reasonNoGit,
  reasonNoAndroid,
  reasonNoIos,
  reasonPlaySecrets,
  reasonAppStoreSecrets,
  reasonDriveSecrets,
  reasonSlackSecrets,
  reasonReportSecrets,
  reasonNeedBuildAab,
  reasonNeedApkBuild,
  reasonNeedBuildIpa,
  reasonNeedCollectAab,
  reasonNeedCollectIpa,
  reasonNeedCollectApk,
  reasonNeedDriveAndApk,
  reasonInvalidProject,
  reasonWhatsAppNumber,
];

class CatalogGroup {
  const CatalogGroup({required this.id, required this.title});

  final String id;
  final String title;
}

class CatalogStep {
  const CatalogStep({
    required this.id,
    required this.groupId,
    required this.label,
    this.iosOnly = false,
  });

  final String id;
  final String groupId;
  final String label;
  final bool iosOnly;

  String get title => Catalog.copyFor(id).title;
  String get blurb => Catalog.copyFor(id).blurb;
}

class StepCopy {
  const StepCopy(this.title, this.blurb);

  final String title;
  final String blurb;
}

class ParentRequirement {
  const ParentRequirement({
    required this.ids,
    required this.reason,
    this.requireAll = false,
  });

  final List<String> ids;
  final String reason;
  final bool requireAll;

  bool isMet(Set<String> selected) {
    if (ids.isEmpty) return true;
    if (requireAll) return ids.every(selected.contains);
    return ids.any(selected.contains);
  }
}

class Catalog {
  static const groupOrder = <CatalogGroup>[
    CatalogGroup(id: 'appInfo', title: 'Version'),
    CatalogGroup(id: 'preGit', title: 'Git before build'),
    CatalogGroup(id: 'common', title: 'Prepare'),
    CatalogGroup(id: 'quality', title: 'Quality'),
    CatalogGroup(id: 'android', title: 'Android'),
    CatalogGroup(id: 'ios', title: 'iOS'),
    CatalogGroup(id: 'postGit', title: 'Git after build'),
    CatalogGroup(id: 'distribution', title: 'Stores'),
    CatalogGroup(id: 'report', title: 'Email'),
    CatalogGroup(id: 'share', title: 'WhatsApp'),
    CatalogGroup(id: 'postBuild', title: 'After the run'),
  ];

  static const iosIds = <String>{
    'podInstall',
    'buildIpa',
    'collectIpa',
    'distAppStore',
  };

  static const mutexGroups = <List<String>>[
    ['pubGet', 'pubUpgrade'],
    ['buildApk', 'buildSplits'],
    ['distPlayProduction', 'distPlayInternal'],
    ['powerShutdown', 'powerSleep', 'powerLock'],
  ];

  static const parentRequirements = <String, ParentRequirement>{
    'collectAab': ParentRequirement(
      ids: ['buildAab'],
      reason: reasonNeedBuildAab,
    ),
    'collectApk': ParentRequirement(
      ids: ['buildApk', 'buildSplits'],
      reason: reasonNeedApkBuild,
    ),
    'collectIpa': ParentRequirement(
      ids: ['buildIpa'],
      reason: reasonNeedBuildIpa,
    ),
    'distPlayProduction': ParentRequirement(
      ids: ['collectAab'],
      reason: reasonNeedCollectAab,
    ),
    'distPlayInternal': ParentRequirement(
      ids: ['collectAab'],
      reason: reasonNeedCollectAab,
    ),
    'distAppStore': ParentRequirement(
      ids: ['collectIpa'],
      reason: reasonNeedCollectIpa,
    ),
    'distDrive': ParentRequirement(
      ids: ['collectApk'],
      reason: reasonNeedCollectApk,
    ),
    'slackNotify': ParentRequirement(
      ids: ['collectApk', 'distDrive'],
      reason: reasonNeedDriveAndApk,
      requireAll: true,
    ),
  };

  static const steps = <CatalogStep>[
    CatalogStep(
      id: 'bumpVersion',
      groupId: 'appInfo',
      label: 'Bump version in pubspec.yaml',
    ),
    CatalogStep(
      id: 'preCommit',
      groupId: 'preGit',
      label: 'Pre-commit (git add and commit)',
    ),
    CatalogStep(
      id: 'prePull',
      groupId: 'preGit',
      label: 'Pre-pull (git pull origin)',
    ),
    CatalogStep(id: 'clean', groupId: 'common', label: 'flutter clean'),
    CatalogStep(id: 'pubGet', groupId: 'common', label: 'flutter pub get'),
    CatalogStep(
      id: 'pubUpgrade',
      groupId: 'common',
      label: 'flutter pub upgrade',
    ),
    CatalogStep(id: 'format', groupId: 'quality', label: 'dart format .'),
    CatalogStep(id: 'analyze', groupId: 'quality', label: 'flutter analyze'),
    CatalogStep(id: 'test', groupId: 'quality', label: 'flutter test'),
    CatalogStep(
      id: 'buildAab',
      groupId: 'android',
      label: 'Build AAB (flutter build aab --release)',
    ),
    CatalogStep(
      id: 'collectAab',
      groupId: 'android',
      label: 'Collect AAB from this run',
    ),
    CatalogStep(
      id: 'buildApk',
      groupId: 'android',
      label: 'Build APK (flutter build apk --release)',
    ),
    CatalogStep(
      id: 'buildSplits',
      groupId: 'android',
      label: 'Build split APKs (flutter build apk --split-per-abi)',
    ),
    CatalogStep(
      id: 'collectApk',
      groupId: 'android',
      label: 'Collect APK from this run',
    ),
    CatalogStep(
      id: 'podInstall',
      groupId: 'ios',
      label: 'pod install --repo-update',
      iosOnly: true,
    ),
    CatalogStep(
      id: 'buildIpa',
      groupId: 'ios',
      label: 'Build IPA (flutter build ipa)',
      iosOnly: true,
    ),
    CatalogStep(
      id: 'collectIpa',
      groupId: 'ios',
      label: 'Collect IPA from this run',
      iosOnly: true,
    ),
    CatalogStep(
      id: 'postCommit',
      groupId: 'postGit',
      label: 'Post-commit (git add and commit)',
    ),
    CatalogStep(
      id: 'postPush',
      groupId: 'postGit',
      label: 'Post-push (git push origin)',
    ),
    CatalogStep(
      id: 'distPlayProduction',
      groupId: 'distribution',
      label: 'Upload AAB to Play (production)',
    ),
    CatalogStep(
      id: 'distPlayInternal',
      groupId: 'distribution',
      label: 'Upload AAB to Play (internal)',
    ),
    CatalogStep(
      id: 'distAppStore',
      groupId: 'distribution',
      label: 'Upload IPA to App Store / TestFlight',
      iosOnly: true,
    ),
    CatalogStep(
      id: 'distDrive',
      groupId: 'distribution',
      label: 'Upload APKs to Google Drive',
    ),
    CatalogStep(
      id: 'slackNotify',
      groupId: 'distribution',
      label: 'Slack notify after Drive',
    ),
    CatalogStep(
      id: 'report',
      groupId: 'report',
      label: 'Email HTML report and logs.txt',
    ),
    CatalogStep(
      id: 'whatsappShare',
      groupId: 'share',
      label: 'Share PDF report and APKs on WhatsApp',
    ),
    CatalogStep(
      id: 'openOutputs',
      groupId: 'postBuild',
      label: 'Open outputs folder',
    ),
    CatalogStep(
      id: 'powerShutdown',
      groupId: 'postBuild',
      label: 'Shut down after delay',
    ),
    CatalogStep(
      id: 'powerSleep',
      groupId: 'postBuild',
      label: 'Sleep after delay',
    ),
    CatalogStep(
      id: 'powerLock',
      groupId: 'postBuild',
      label: 'Lock after delay',
    ),
  ];

  static const copy = <String, StepCopy>{
    'bumpVersion': StepCopy(
      'Set app version',
      'Writes the version and build number into pubspec.yaml.',
    ),
    'preCommit': StepCopy(
      'Save work before build',
      'Commits current files so the build starts from a clean snapshot.',
    ),
    'prePull': StepCopy(
      'Pull latest from git',
      'Fetches the latest commits on your branch before building.',
    ),
    'clean': StepCopy(
      'Clean old build files',
      'Clears leftover Flutter build output so the next compile is fresh.',
    ),
    'pubGet': StepCopy(
      'Install packages',
      'Downloads the exact packages listed in pubspec.lock.',
    ),
    'pubUpgrade': StepCopy(
      'Upgrade packages',
      'Updates packages to newer allowed versions. Do not pick with Install packages.',
    ),
    'format': StepCopy('Format Dart', 'Runs dart format on the project.'),
    'analyze': StepCopy('Analyze Dart', 'Runs flutter analyze for issues.'),
    'test': StepCopy('Run tests', 'Runs flutter test.'),
    'buildAab': StepCopy(
      'Build Play bundle (AAB)',
      'Creates the Android App Bundle used for Play Store upload.',
    ),
    'collectAab': StepCopy(
      'Save the AAB',
      'Copies this run\'s AAB into the outputs folder.',
    ),
    'buildApk': StepCopy(
      'Build one APK',
      'Creates a single installable APK. Do not pick with split APKs.',
    ),
    'buildSplits': StepCopy(
      'Build split APKs',
      'Creates per-ABI APKs (v7a and v8a). Do not pick with one APK.',
    ),
    'collectApk': StepCopy(
      'Save the APKs',
      'Copies this run\'s APK files into the outputs folder.',
    ),
    'podInstall': StepCopy(
      'Install iOS pods',
      'Runs pod install so the iOS build has its native dependencies.',
    ),
    'buildIpa': StepCopy(
      'Build iPhone IPA',
      'Creates the iOS IPA for TestFlight or the App Store.',
    ),
    'collectIpa': StepCopy(
      'Save the IPA',
      'Copies this run\'s IPA into the outputs folder.',
    ),
    'postCommit': StepCopy(
      'Commit after build',
      'Commits files changed by the pipeline, such as the version bump.',
    ),
    'postPush': StepCopy(
      'Push to git',
      'Pushes the branch to origin. Never force-pushes.',
    ),
    'distPlayProduction': StepCopy(
      'Upload to Play production',
      'Sends the AAB to the production track. Needs Play credentials.',
    ),
    'distPlayInternal': StepCopy(
      'Upload to Play internal',
      'Sends the AAB to the internal test track. Needs Play credentials.',
    ),
    'distAppStore': StepCopy(
      'Upload to TestFlight',
      'Sends the IPA to App Store Connect. Needs Apple API keys.',
    ),
    'distDrive': StepCopy(
      'Upload APKs to Drive',
      'Shares collected APKs on Google Drive. Needs Drive OAuth files.',
    ),
    'slackNotify': StepCopy(
      'Notify Slack',
      'Posts a Drive link to Slack after the upload.',
    ),
    'report': StepCopy(
      'Email the report',
      'Sends an HTML report and logs.txt. Needs Gmail secrets.',
    ),
    'whatsappShare': StepCopy(
      'Send PDF and APKs on WhatsApp',
      'Reads the logs, builds a short HTML report, prints a PDF, then sends it with APKs.',
    ),
    'openOutputs': StepCopy(
      'Open outputs folder',
      'Opens the folder that holds this run\'s files.',
    ),
    'powerShutdown': StepCopy(
      'Shut down after',
      'Shuts the computer down after a delay. Needs a second confirm.',
    ),
    'powerSleep': StepCopy(
      'Sleep after',
      'Puts the computer to sleep after a delay. Needs a second confirm.',
    ),
    'powerLock': StepCopy(
      'Lock after',
      'Locks the screen after a delay. Needs a second confirm.',
    ),
  };

  static StepCopy copyFor(String id) {
    return copy[id] ?? StepCopy(id, '');
  }

  static List<CatalogStep> forHost({required bool isMacOS}) {
    return [
      for (final step in steps)
        if (isMacOS || !step.iosOnly) step,
    ];
  }

  static Set<String> idsForHost({required bool isMacOS}) {
    return {for (final step in forHost(isMacOS: isMacOS)) step.id};
  }

  static List<CatalogGroup> groupsFor(List<CatalogStep> hostSteps) {
    final used = {for (final step in hostSteps) step.groupId};
    return [
      for (final group in groupOrder)
        if (used.contains(group.id)) group,
    ];
  }

  static List<String> mutexConflict(Iterable<String> selected) {
    final set = selected.toSet();
    for (final group in mutexGroups) {
      final hit = [
        for (final id in group)
          if (set.contains(id)) id,
      ];
      if (hit.length > 1) return hit;
    }
    return const [];
  }
}
