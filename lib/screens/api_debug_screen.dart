import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:quran_app/config/api_config.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/services/outbox_service.dart';
import 'package:quran_app/services/sync_worker.dart';

/// Hidden jawhar-api debug screen (roadmap §10).
///
/// Reached by long-pressing the version tile in Profile → Account → About.
/// Exercises the Cloud Run API directly, regardless of [kUseApiV1Ai]:
///   1. GET  /health                  (no auth)
///   2. GET  /v1/me/bootstrap         (Firebase ID token)
///   3. POST /v1/me/plan:enhance      (Firebase ID token, tiny canary context)
/// plus the Phase 4 outbox panel: pending/poisoned counts, oldest pending
/// age, last drain result, cached writePath/datasetEpoch, a manual drain
/// and the §7.3 "Reconcile" action (re-runs backfill + drain).
///
/// Debug-only surface: strings are intentionally plain English (not l10n).
class ApiDebugScreen extends StatefulWidget {
  const ApiDebugScreen({super.key});

  @override
  State<ApiDebugScreen> createState() => _ApiDebugScreenState();
}

class _ApiDebugScreenState extends State<ApiDebugScreen> {
  late final TextEditingController _baseUrlController;
  bool _busy = false;
  String _output = 'No request sent yet.';

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController(text: kJawharApiBaseUrl);
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    super.dispose();
  }

  String get _baseUrl {
    final raw = _baseUrlController.text.trim();
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  Future<String?> _idToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> _run(
    String label,
    Future<http.Response> Function(http.Client client) send,
  ) async {
    if (_busy) return;
    if (_baseUrl.isEmpty) {
      setState(() {
        _output =
            '$label\n\nNo base URL configured.\n'
            'Enter the Cloud Run URL above (e.g. '
            'https://jawhar-api-xyz.a.run.app) or build with '
            '--dart-define=JAWHAR_API_BASE_URL=...';
      });
      return;
    }

    setState(() {
      _busy = true;
      _output = '$label\n\nSending...';
    });

    final stopwatch = Stopwatch()..start();
    final client = http.Client();
    try {
      final response = await send(client).timeout(const Duration(seconds: 25));
      stopwatch.stop();
      setState(() {
        _output =
            '$label\n'
            'HTTP ${response.statusCode} in ${stopwatch.elapsedMilliseconds} ms\n\n'
            '${_prettify(response.body)}';
      });
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _output =
            '$label\n'
            'FAILED after ${stopwatch.elapsedMilliseconds} ms\n\n$e';
      });
    } finally {
      client.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  String _prettify(String body) {
    if (body.isEmpty) return '(empty body)';
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(jsonDecode(body));
    } catch (_) {
      return body; // Not JSON — show raw.
    }
  }

  Future<void> _runHealthz() {
    // /health, not /healthz: Cloud Run's frontend swallows /healthz on
    // *.run.app hosts and returns a Google 404 without hitting the server.
    return _run('GET /health', (client) {
      return client.get(Uri.parse('$_baseUrl/health'));
    });
  }

  Future<void> _runAuthenticated(
    String label,
    Future<http.Response> Function(http.Client client, String token) send,
  ) async {
    final token = await _idToken();
    if (token == null || token.isEmpty) {
      setState(() {
        _output =
            '$label\n\nNot signed in — this endpoint needs a Firebase ID '
            'token. Sign in on the Account tab first.';
      });
      return;
    }
    await _run(label, (client) => send(client, token));
  }

  Future<void> _runBootstrap() {
    return _runAuthenticated('GET /v1/me/bootstrap', (client, token) {
      return client.get(
        Uri.parse('$_baseUrl/v1/me/bootstrap'),
        headers: {'Authorization': 'Bearer $token'},
      );
    });
  }

  Future<void> _showOutboxState() async {
    final outbox = context.read<OutboxService>();
    final worker = context.read<SyncWorker>();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    setState(() => _busy = true);
    try {
      final all = await outbox.stats();
      final mine = uid == null ? null : await outbox.stats(uid: uid);
      final nowUtc = DateTime.now().toUtc();
      final lines = <String>[
        'Outbox state',
        '',
        'writePath (cached): ${worker.currentWritePath}',
        'datasetEpoch: ${worker.datasetEpoch ?? '(none yet)'}',
        'pending (all uids): ${all.pending} · poisoned: ${all.poisoned}',
        if (mine != null)
          'pending ($uid): ${mine.pending} · poisoned: ${mine.poisoned}',
        'oldest pending age: '
            '${all.oldestAge(nowUtc)?.toString() ?? '(empty)'}',
        'draining now: ${worker.isDraining}',
        'last drain: ${worker.lastDrainResult?.toString() ?? '(never)'}',
        if (worker.lastDrainResult != null)
          'last drain at: ${worker.lastDrainResult!.atUtc.toIso8601String()}',
        'last bootstrap meta: '
            '${worker.lastBootstrapAtUtc?.toIso8601String() ?? '(never)'}',
      ];
      setState(() => _output = lines.join('\n'));
    } catch (e) {
      setState(() => _output = 'Outbox state\n\nFAILED: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runDrain() async {
    final worker = context.read<SyncWorker>();
    setState(() {
      _busy = true;
      _output = 'Manual drain\n\nDraining...';
    });
    try {
      await worker.requestDrain(trigger: 'debug-screen');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (mounted) await _showOutboxState();
  }

  Future<void> _runReconcile() async {
    final worker = context.read<SyncWorker>();
    if (FirebaseAuth.instance.currentUser == null) {
      setState(() {
        _output =
            'Reconcile\n\nNot signed in — reconcile re-enqueues local '
            'history for the signed-in uid. Sign in first.';
      });
      return;
    }
    setState(() {
      _busy = true;
      _output = 'Reconcile\n\nRe-running backfill + drain...';
    });
    try {
      await worker.reconcile();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (mounted) await _showOutboxState();
  }

  /// Recovery lever for rows poisoned by a since-cleared environmental
  /// condition (e.g. a transient server-side 403): re-marks them pending
  /// and drains.
  Future<void> _retryPoisonedRows() async {
    final outbox = context.read<OutboxService>();
    final worker = context.read<SyncWorker>();
    setState(() {
      _busy = true;
      _output = 'Retry poisoned rows\n\nReviving + draining...';
    });
    try {
      final revived = await outbox.retryPoisonedRows();
      await worker.requestDrain(trigger: 'debug-retry-poisoned');
      if (mounted) {
        setState(() => _output = 'Retry poisoned rows\n\nRevived $revived');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _output = 'Retry poisoned rows\n\nFAILED: $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (mounted) await _showOutboxState();
  }

  Future<void> _runPlanEnhanceCanary() {
    return _runAuthenticated('POST /v1/me/plan:enhance (canary)', (
      client,
      token,
    ) {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final canaryPayload = <String, dynamic>{
        'canary': true,
        'isRecoveryMode': false,
        'context': {
          'profile': {
            'age': 25,
            'ageGroup': 'youngAdult',
            'dailyTimeMinutes': 15,
            'pacePreference': 'steady',
            'hifzExperience': 'fresh',
            'startingPage': 582,
            'activeDays': [0, 1, 2, 3, 4, 5, 6],
          },
          'progress': {'memorizedPages': 2, 'inProgressPages': 1},
          'recentSessions': <Map<String, dynamic>>[],
          'temporal': {'date': today, 'isActiveDay': true},
        },
      };
      return client.post(
        Uri.parse('$_baseUrl/v1/me/plan:enhance'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(canaryPayload),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackground,
        foregroundColor: theme.primaryText,
        elevation: 0,
        title: Text(
          'API Debug',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.primaryText,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Build flags: USE_API_V1_AI=$kUseApiV1Ai · '
                'JAWHAR_API_BASE_URL='
                '${kJawharApiBaseUrl.isEmpty ? '(empty)' : kJawharApiBaseUrl}\n'
                'Signed in: ${user != null ? (user.email ?? user.uid) : 'no'}',
                style: TextStyle(fontSize: 11, color: theme.mutedText),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _baseUrlController,
                style: TextStyle(fontSize: 13, color: theme.primaryText),
                decoration: InputDecoration(
                  labelText: 'API base URL',
                  hintText: 'https://jawhar-api-xyz.a.run.app',
                  labelStyle: TextStyle(color: theme.mutedText),
                  hintStyle: TextStyle(color: theme.mutedText),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: _busy ? null : _runHealthz,
                    child: const Text('GET /health'),
                  ),
                  ElevatedButton(
                    onPressed: _busy ? null : _runBootstrap,
                    child: const Text('GET /v1/me/bootstrap'),
                  ),
                  ElevatedButton(
                    onPressed: _busy ? null : _runPlanEnhanceCanary,
                    child: const Text('POST plan:enhance canary'),
                  ),
                  ElevatedButton(
                    onPressed: _busy ? null : _showOutboxState,
                    child: const Text('Outbox state'),
                  ),
                  ElevatedButton(
                    onPressed: _busy ? null : _runDrain,
                    child: const Text('Drain outbox'),
                  ),
                  ElevatedButton(
                    onPressed: _busy ? null : _runReconcile,
                    child: const Text('Reconcile (backfill + drain)'),
                  ),
                  ElevatedButton(
                    onPressed: _busy ? null : _retryPoisonedRows,
                    child: const Text('Retry poisoned rows'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _output,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: theme.primaryText,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
