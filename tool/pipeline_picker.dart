import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'pipeline_picker/cache_io.dart';
import 'pipeline_picker/catalog.dart';
import 'pipeline_picker/host_actions.dart';
import 'pipeline_picker/io_helpers.dart';
import 'pipeline_picker/open_page.dart';
import 'pipeline_picker/readiness.dart';
import 'pipeline_picker/whatsapp.dart';

const _help = '''
Fluship agent pipeline picker.

Usage:
  dart tool/pipeline_picker.dart [--workspace PATH] [--timeout-seconds 600] [--no-browser]

If Cursor IDE is open, the page opens in the Cursor browser panel.
Chrome opens only when Cursor is not running.

Stdout always includes:
  Pipeline picker: http://127.0.0.1:PORT/
  open-in: cursor-ide|chrome

Exit codes:
  0  submitted
  2  cancelled
  3  timeout
  1  error
''';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_help);
    return;
  }

  final parsed = _parseArgs(args);
  final toolDir = File.fromUri(Platform.script).parent;
  final workspace = Directory(
    parsed.workspace ?? toolDir.parent.path,
  ).absolute.path;
  final webDir = pathJoin(toolDir.path, 'pipeline_picker', 'web');
  final agentDir = pathJoin(workspace, '.fluship-agent');
  Directory(agentDir).createSync(recursive: true);

  final cachePath = pathJoin(agentDir, 'pipeline-cache.json');
  final secretsPath = pathJoin(agentDir, 'secrets.json');
  final lockPath = pathJoin(agentDir, 'picker.lock');
  final resultPath = pathJoin(agentDir, 'picker-result.json');

  final existing = _liveLock(lockPath);
  if (existing != null) {
    final url = asString(existing['url']);
    if (url.isNotEmpty) {
      await _announcePicker(agentDir, url, open: parsed.openBrowser);
    }
    exit(_waitForResult(resultPath, asInt(existing['pid']) ?? 0));
  }

  if (File(resultPath).existsSync()) {
    File(resultPath).deleteSync();
  }

  final picker = _PickerApp(
    webDir: webDir,
    cachePath: cachePath,
    secretsPath: secretsPath,
    lockPath: lockPath,
    resultPath: resultPath,
    timeout: Duration(seconds: parsed.timeoutSeconds),
  );

  final url = await picker.start();
  writeJsonFile(lockPath, {
    'pid': pid,
    'port': picker.port,
    'url': url,
    'startedAt': DateTime.now().toUtc().toIso8601String(),
  });

  await _announcePicker(agentDir, url, open: parsed.openBrowser);

  final code = await picker.done.future;
  await picker.close();
  _deleteIfExists(lockPath);
  exit(code);
}

class _Args {
  const _Args({
    required this.workspace,
    required this.timeoutSeconds,
    required this.openBrowser,
  });

  final String? workspace;
  final int timeoutSeconds;
  final bool openBrowser;
}

_Args _parseArgs(List<String> args) {
  String? workspace;
  var timeoutSeconds = 600;
  var openBrowser = true;
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--no-browser') {
      openBrowser = false;
      continue;
    }
    if (arg == '--workspace' && i + 1 < args.length) {
      workspace = args[++i];
      continue;
    }
    if (arg == '--timeout-seconds' && i + 1 < args.length) {
      timeoutSeconds = int.tryParse(args[++i]) ?? timeoutSeconds;
      continue;
    }
  }
  return _Args(
    workspace: workspace,
    timeoutSeconds: timeoutSeconds,
    openBrowser: openBrowser,
  );
}

Map<String, dynamic>? _liveLock(String lockPath) {
  final lock = readJsonFile(lockPath);
  final lockPid = asInt(lock['pid']);
  if (lockPid == null || !pidAlive(lockPid)) {
    _deleteIfExists(lockPath);
    return null;
  }
  return lock;
}

Future<void> _announcePicker(
  String agentDir,
  String url, {
  required bool open,
}) async {
  final openIn = await openPickerPage(url, open: open);
  writeJsonFile(pathJoin(agentDir, 'picker-open.json'), {
    'url': url,
    'openIn': openIn,
  });
  stdout.writeln('Pipeline picker: $url');
  stdout.writeln('open-in: $openIn');
  if (openIn == openInCursorIde) {
    stdout.writeln(
      'Open that URL in the Cursor IDE browser panel now. Do not open Chrome.',
    );
  }
}

int _waitForResult(String resultPath, int lockPid) {
  final deadline = DateTime.now().add(const Duration(minutes: 11));
  while (DateTime.now().isBefore(deadline)) {
    if (File(resultPath).existsSync()) {
      return asInt(readJsonFile(resultPath)['exitCode']) ?? 1;
    }
    if (!pidAlive(lockPid)) {
      if (File(resultPath).existsSync()) {
        return asInt(readJsonFile(resultPath)['exitCode']) ?? 1;
      }
      return 1;
    }
    sleep(const Duration(milliseconds: 400));
  }
  return 3;
}

void _deleteIfExists(String path) {
  final file = File(path);
  if (file.existsSync()) file.deleteSync();
}

class _PickerApp {
  _PickerApp({
    required this.webDir,
    required this.cachePath,
    required this.secretsPath,
    required this.lockPath,
    required this.resultPath,
    required this.timeout,
  });

  final String webDir;
  final String cachePath;
  final String secretsPath;
  final String lockPath;
  final String resultPath;
  final Duration timeout;
  final done = Completer<int>();

  late HttpServer _server;
  Timer? _idle;
  int get port => _server.port;

  Future<String> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _bumpIdle();
    _server.listen(_handle);
    return 'http://127.0.0.1:$port/';
  }

  Future<void> close() async {
    _idle?.cancel();
    await _server.close(force: true);
  }

  void _bumpIdle() {
    _idle?.cancel();
    _idle = Timer(timeout, () {
      _finish(3, 'timeout');
    });
  }

  void _finish(int code, String status) {
    writeJsonFile(resultPath, {
      'status': status,
      'exitCode': code,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    });
    if (!done.isCompleted) done.complete(code);
  }

  Future<void> _handle(HttpRequest request) async {
    _bumpIdle();
    try {
      final path = request.uri.path;
      if (request.method == 'GET' && path == '/api/state') {
        await _json(request, _stateFromCache());
        return;
      }
      if (request.method == 'POST' && path == '/api/readiness') {
        final body = await _readJson(request);
        await _json(request, _stateFromRequest(body));
        return;
      }
      if (request.method == 'POST' && path == '/api/validate') {
        final body = await _readJson(request);
        await _json(request, _validate(body));
        return;
      }
      if (request.method == 'POST' && path == '/api/browse') {
        final body = await _readJson(request);
        final picked = await browseFolder();
        if (picked == null || picked.isEmpty) {
          await _json(request, {
            'error':
                'Browse cancelled or unavailable. Paste a path and validate.',
          });
          return;
        }
        await _json(request, _validate({...body, 'path': picked}));
        return;
      }
      if (request.method == 'POST' && path == '/api/submit') {
        await _submit(request);
        return;
      }
      if (request.method == 'POST' && path == '/api/cancel') {
        await _html(
          request,
          _closedPage('Cancelled', 'No pipeline steps were saved.'),
        );
        _finish(2, 'cancelled');
        return;
      }
      if (request.method == 'GET' && path == '/') {
        await _file(request, 'index.html', 'text/html; charset=utf-8');
        return;
      }
      if (request.method == 'GET' && !path.contains('..')) {
        final relative = path.startsWith('/') ? path.substring(1) : path;
        if (relative.isNotEmpty && !relative.startsWith('api/')) {
          await _file(request, relative, _mimeFor(relative));
          return;
        }
      }
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
    } catch (error) {
      request.response.statusCode = HttpStatus.internalServerError;
      await _json(request, {'error': '$error'});
    }
  }

  Future<Map<String, dynamic>> _readJson(HttpRequest request) async {
    final raw = await utf8.decodeStream(request);
    if (raw.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry('$key', value));
    }
    return <String, dynamic>{};
  }

  Map<String, dynamic> _stateFromCache() {
    final cache = loadPipelineCache(cachePath);
    final isFirstRun = !cache.hasSavedProject;
    final savedPath = cache.targetProjectPath.trim();
    final project = isFirstRun
        ? ProjectFacts.empty
        : ProjectFacts.inspect(savedPath);
    final useSaved = !isFirstRun && project.isValidFlutterProject;
    return _buildState(
      cache: cache,
      project: useSaved ? project : (isFirstRun ? ProjectFacts.empty : project),
      selectedHint: useSaved ? cache.selected : const [],
      isFirstRun: isFirstRun,
      incomingNumber: '',
    );
  }

  Map<String, dynamic> _stateFromRequest(Map<String, dynamic> body) {
    final cache = loadPipelineCache(cachePath);
    final path = asString(body['path']);
    final selected = asStringList(body['selected']);
    return _buildState(
      cache: cache,
      project: ProjectFacts.inspect(path),
      selectedHint: selected,
      isFirstRun: !cache.hasSavedProject,
      incomingNumber: asString(body['whatsappNumber']),
    );
  }

  Map<String, dynamic> _validate(Map<String, dynamic> body) {
    final cache = loadPipelineCache(cachePath);
    final path = asString(body['path']);
    final project = ProjectFacts.inspect(path);
    final selected = asStringList(body['selected']);
    final state = _buildState(
      cache: cache,
      project: project,
      selectedHint: selected,
      isFirstRun: !cache.hasSavedProject,
      incomingNumber: asString(body['whatsappNumber']),
    );
    if (!project.hasProject) {
      return {...state, 'valid': false, 'projectError': reasonSelectProject};
    }
    if (!project.hasPubspec) {
      return {...state, 'valid': false, 'projectError': reasonInvalidProject};
    }
    return {
      ...state,
      'valid': true,
      'projectError': '',
      'versionFromPubspec': project.version,
      'buildNumberFromPubspec': project.buildNumber,
    };
  }

  Map<String, dynamic> _buildState({
    required PipelineCache cache,
    required ProjectFacts project,
    required Iterable<String> selectedHint,
    required bool isFirstRun,
    required String incomingNumber,
  }) {
    final whatsappNumber = resolveWhatsAppNumber(
      cached: cache.whatsappNumber,
      incoming: incomingNumber,
    );
    final isMacOS = Platform.isMacOS;
    final hostSteps = Catalog.forHost(isMacOS: isMacOS);
    final hostIds = Catalog.idsForHost(isMacOS: isMacOS);
    final saved = {
      for (final id in cache.selected)
        if (hostIds.contains(id)) id,
    };
    final hint = {
      for (final id in selectedHint)
        if (hostIds.contains(id)) id,
    };

    var readiness = evaluateReadiness(
      catalog: hostSteps,
      project: project,
      secrets: SecretsFacts.fromJson(readJsonFile(secretsPath)),
      selected: hint,
      whatsappNumber: whatsappNumber,
    );
    var checked = filterSelected(hint, readiness);
    readiness = evaluateReadiness(
      catalog: hostSteps,
      project: project,
      secrets: SecretsFacts.fromJson(readJsonFile(secretsPath)),
      selected: checked,
      whatsappNumber: whatsappNumber,
    );
    checked = filterSelected(checked, readiness);

    final byId = {for (final step in readiness) step.id: step};
    final sameProject =
        project.path.isNotEmpty &&
        absolutePath(cache.targetProjectPath) == project.path;
    final version = sameProject && cache.version.isNotEmpty
        ? cache.version
        : (project.version.isNotEmpty ? project.version : cache.version);
    final buildNumber = sameProject && cache.buildNumber.isNotEmpty
        ? cache.buildNumber
        : (project.buildNumber.isNotEmpty
              ? project.buildNumber
              : cache.buildNumber);

    final groups = <Map<String, dynamic>>[];
    for (final group in Catalog.groupsFor(hostSteps)) {
      final steps = <Map<String, dynamic>>[];
      for (final step in hostSteps) {
        if (step.groupId != group.id) continue;
        final ready = byId[step.id]!;
        final savedButBlocked = saved.contains(step.id) && !ready.enabled;
        steps.add({
          'id': step.id,
          'title': step.title,
          'blurb': step.blurb,
          'label': step.label,
          'enabled': ready.enabled,
          'checked': checked.contains(step.id),
          'reason': ready.reason,
          'savedButBlocked': savedButBlocked,
        });
      }
      groups.add({'id': group.id, 'title': group.title, 'steps': steps});
    }

    var recents = [
      for (final item in cache.recentProjectPaths)
        if (ProjectFacts.inspect(item).isValidFlutterProject)
          absolutePath(item),
    ];
    if (project.isValidFlutterProject) {
      recents = rememberProject(recents, project.path);
    }

    var projectError = '';
    if (!project.hasProject) {
      projectError = isFirstRun ? '' : reasonSelectProject;
    } else if (!project.hasPubspec) {
      projectError = reasonInvalidProject;
    }

    return {
      'hostOs': hostOsName(),
      'isFirstRun': isFirstRun,
      'projectPath': project.path,
      'projectValid': project.isValidFlutterProject,
      'projectError': projectError,
      'recentProjectPaths': recents,
      'version': version,
      'buildNumber': buildNumber,
      'gitBranch': cache.gitBranch.isEmpty ? 'master' : cache.gitBranch,
      'preCommitMessage': cache.preCommitMessage,
      'postCommitMessage': cache.postCommitMessage,
      'releaseNotes': cache.releaseNotes,
      'emailRecipient': cache.emailRecipient,
      'whatsappNumber': whatsappNumber,
      'powerDelaySeconds': cache.powerDelaySeconds,
      'selectedCount': checked.length,
      'mutex': Catalog.mutexGroups,
      'groups': groups,
    };
  }

  Future<void> _submit(HttpRequest request) async {
    final body = await _readJson(request);
    final path = asString(body['path']);
    final project = ProjectFacts.inspect(path);
    if (!project.isValidFlutterProject) {
      request.response.statusCode = HttpStatus.badRequest;
      await _json(request, {'error': reasonInvalidProject});
      return;
    }

    final isMacOS = Platform.isMacOS;
    final hostSteps = Catalog.forHost(isMacOS: isMacOS);
    final requested = hostSelectedIds(
      selected: asStringList(body['selected']),
      isMacOS: isMacOS,
    );
    final mutex = Catalog.mutexConflict(requested);
    if (mutex.isNotEmpty) {
      request.response.statusCode = HttpStatus.badRequest;
      await _json(request, {'error': 'Pick only one of: ${mutex.join(', ')}.'});
      return;
    }

    final whatsappNumber = asString(body['whatsappNumber']);
    var readiness = evaluateReadiness(
      catalog: hostSteps,
      project: project,
      secrets: SecretsFacts.fromJson(readJsonFile(secretsPath)),
      selected: requested.toSet(),
      whatsappNumber: whatsappNumber.isEmpty
          ? defaultWhatsAppNumber
          : whatsappNumber,
    );
    final selected = filterSelected(requested, readiness).toList();
    readiness = evaluateReadiness(
      catalog: hostSteps,
      project: project,
      secrets: SecretsFacts.fromJson(readJsonFile(secretsPath)),
      selected: selected.toSet(),
      whatsappNumber: whatsappNumber.isEmpty
          ? defaultWhatsAppNumber
          : whatsappNumber,
    );
    final allowed = filterSelected(selected, readiness).toList();

    final version = asString(body['version']);
    final buildNumber = asString(body['buildNumber']);
    final gitBranch = asString(body['gitBranch'], 'master');
    const gitIds = {'preCommit', 'prePull', 'postCommit', 'postPush'};
    final needsVersion =
        allowed.contains('bumpVersion') || allowed.any(gitIds.contains);
    if (needsVersion && (version.isEmpty || buildNumber.isEmpty)) {
      request.response.statusCode = HttpStatus.badRequest;
      await _json(request, {
        'error':
            'Version and build number are required for version or git steps.',
      });
      return;
    }

    final existing = loadPipelineCache(cachePath);
    final cache = existing.copyWith(
      selected: allowed,
      version: version,
      buildNumber: buildNumber,
      gitBranch: gitBranch,
      targetProjectPath: project.path,
      recentProjectPaths: rememberProject(
        existing.recentProjectPaths,
        project.path,
      ),
      preCommitMessage: asString(
        body['preCommitMessage'],
        existing.preCommitMessage,
      ),
      postCommitMessage: asString(
        body['postCommitMessage'],
        existing.postCommitMessage,
      ),
      releaseNotes: asString(body['releaseNotes'], existing.releaseNotes),
      emailRecipient: asString(body['emailRecipient'], existing.emailRecipient),
      whatsappNumber: whatsappNumber,
      playTrack: playTrackFor(allowed),
      powerAction: powerActionFor(allowed),
      powerDelaySeconds:
          asInt(body['powerDelaySeconds']) ?? existing.powerDelaySeconds,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
      clearPlayTrack: playTrackFor(allowed) == null,
      clearPowerAction: powerActionFor(allowed) == null,
    );
    savePipelineCache(cachePath, cache);

    await _html(
      request,
      _closedPage('Saved', 'You can close this tab. The agent will continue.'),
    );
    _finish(0, 'submitted');
  }

  Future<void> _file(HttpRequest request, String name, String type) async {
    final file = File(pathJoin(webDir, name));
    if (!file.existsSync()) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    request.response.headers.contentType = ContentType.parse(type);
    request.response.headers.set('Cache-Control', 'no-store');
    await request.response.addStream(file.openRead());
    await request.response.close();
  }

  Future<void> _json(HttpRequest request, Map<String, dynamic> data) async {
    request.response.headers.contentType = ContentType.json;
    request.response.headers.set('Cache-Control', 'no-store');
    request.response.write(jsonEncode(data));
    await request.response.close();
  }

  Future<void> _html(HttpRequest request, String html) async {
    request.response.headers.contentType = ContentType.html;
    request.response.headers.set('Cache-Control', 'no-store');
    request.response.write(html);
    await request.response.close();
  }
}

String _mimeFor(String relative) {
  if (relative.endsWith('.css')) return 'text/css; charset=utf-8';
  if (relative.endsWith('.js')) return 'text/javascript; charset=utf-8';
  if (relative.endsWith('.html')) return 'text/html; charset=utf-8';
  if (relative.endsWith('.woff2')) return 'font/woff2';
  if (relative.endsWith('.woff')) return 'font/woff';
  return 'application/octet-stream';
}

String _closedPage(String title, String message) {
  return '''
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>$title</title>
  <link rel="stylesheet" href="/styles.css">
</head>
<body>
  <main class="dialog done">
    <h1>$title</h1>
    <p class="lede">$message</p>
  </main>
</body>
</html>
''';
}
