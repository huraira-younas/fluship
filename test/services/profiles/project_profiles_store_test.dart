import 'package:fluship/services/project_service.dart/project_profiles_store.dart';
import 'package:fluship/core/shared_prefs/shared_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProjectProfilesStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefs.i.init();
    store = ProjectProfilesStore();
  });

  test('saves profiles by project name and activates the latest', () async {
    await store.saveProfile('reelstay', {
      'appInfo': {'version': '1.0.0'},
    });
    await store.saveProfile('call_it', {
      'appInfo': {'version': '2.0.0'},
    });

    expect(store.activeProject, 'call_it');
    expect(store.projectNames, ['call_it', 'reelstay']);
    expect(store.getProfile('reelstay'), {
      'appInfo': {'version': '1.0.0'},
    });
  });

  test('renames a profile and keeps it active', () async {
    await store.saveProfile('old_name', {'appInfo': {}});
    await store.renameProfile(
      newProjectName: 'new_name',
      oldProjectName: 'old_name',
    );

    expect(store.activeProject, 'new_name');
    expect(store.projectNames, ['new_name']);
    expect(store.getProfile('old_name'), isNull);
    expect(store.getProfile('new_name'), isNotNull);
  });

  test('clears only the active project selection', () async {
    await store.saveProfile('reelstay', {'appInfo': {}});
    await store.clearActiveProject();

    expect(store.activeProject, isNull);
    expect(store.projectNames, ['reelstay']);
  });

  test('deletes a profile and clears it when active', () async {
    await store.saveProfile('call_it', {'appInfo': {}});
    await store.saveProfile('reelstay', {'appInfo': {}});

    final deleted = await store.deleteProfile('reelstay');

    expect(deleted, isTrue);
    expect(store.activeProject, isNull);
    expect(store.projectNames, ['call_it']);
    expect(store.getProfile('reelstay'), isNull);
  });

  test('ignores deletion of a missing profile', () async {
    await store.saveProfile('reelstay', {'appInfo': {}});

    final deleted = await store.deleteProfile('missing');

    expect(deleted, isFalse);
    expect(store.activeProject, 'reelstay');
    expect(store.projectNames, ['reelstay']);
  });

  test('does not overwrite another profile while renaming', () async {
    await store.saveProfile('reelstay', {'appInfo': {}});
    await store.saveProfile('call_it', {'appInfo': {}});

    expect(
      () => store.renameProfile(
        newProjectName: 'reelstay',
        oldProjectName: 'call_it',
      ),
      throwsStateError,
    );
    expect(store.projectNames, ['call_it', 'reelstay']);
  });
}
