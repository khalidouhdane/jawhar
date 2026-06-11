// R1 spike, items (b) and (c) — run manually with the Firestore emulator up:
//   firebase emulators:start --only firestore --project quran-app-e5e86
//   FIRESTORE_EMULATOR_HOST=localhost:8080 dart run tool/spike/spike_firestore_emulator.dart
//
// (b) Firestore transactions through FirestoreGateway against the EMULATOR:
//     read-modify-write, multi-doc atomic write, and 10 concurrent
//     increments of one counter (proves transactional isolation/retry).
// (c) FIRESTORE_EMULATOR_HOST honored by firebase_admin_sdk /
//     google_cloud_firestore: no credentials are configured at all (any
//     production call would be rejected), and the written documents are read
//     back through the emulator's REST endpoint directly.

import 'dart:io';

import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:jawhar_api/gateway/firestore_gateway.dart';

// 'demo-' prefix = offline-only project by Firebase convention; this project
// does not exist in production, so nothing here could have hit prod.
const projectId = 'demo-jawhar-spike';

final results = <String, String>{};

void record(String item, bool pass, String evidence) {
  results[item] = pass ? 'PASS' : 'FAIL';
  stdout.writeln('[${pass ? 'PASS' : 'FAIL'}] $item — $evidence');
}

Future<void> main() async {
  final emulatorHost = Platform.environment['FIRESTORE_EMULATOR_HOST'];
  if (emulatorHost == null || emulatorHost.isEmpty) {
    stderr.writeln('FIRESTORE_EMULATOR_HOST must be set (e.g. localhost:8080).');
    exitCode = 2;
    return;
  }

  record(
    'c0-emulator-detected',
    FirestoreGateway.isUsingEmulator,
    'FirestoreGateway.isUsingEmulator=${FirestoreGateway.isUsingEmulator} '
    'with FIRESTORE_EMULATOR_HOST=$emulatorHost',
  );

  // No credential anywhere: AppOptions has neither credential nor httpClient.
  final app = FirebaseApp.initializeApp(
    options: const AppOptions(projectId: projectId),
  );
  final gateway = FirestoreGateway.forApp(app);
  final runId = DateTime.now().millisecondsSinceEpoch;
  final base = 'spike_runs/$runId';

  // --- plain set/get roundtrip --------------------------------------------
  try {
    await gateway.setDoc(base, {'hello': 'emulator', 'runId': runId});
    final readBack = await gateway.getDoc(base);
    record(
      'b1-set-get-roundtrip',
      readBack != null &&
          readBack['hello'] == 'emulator' &&
          readBack['runId'] == runId,
      'setDoc/getDoc roundtrip on $base -> $readBack',
    );
  } catch (e) {
    record('b1-set-get-roundtrip', false, 'threw: $e');
  }

  // --- transaction: read-modify-write + multi-doc atomicity ---------------
  try {
    final result = await gateway.runTransaction<int>((tx) async {
      final doc = await tx.get(base);
      final next = (doc?['runId'] as int? ?? 0) + 1;
      tx.set(base, {'counter': next}, merge: true);
      tx.set('$base/audit/first', {'wroteCounter': next});
      return next;
    });
    final audit = await gateway.getDoc('$base/audit/first');
    record(
      'b2-transaction-rmw-multidoc',
      result == runId + 1 && audit?['wroteCounter'] == runId + 1,
      'runTransaction read runId=$runId, wrote counter=${runId + 1} to two '
      'docs atomically; audit doc says ${audit?['wroteCounter']}',
    );
  } catch (e) {
    record('b2-transaction-rmw-multidoc', false, 'threw: $e');
  }

  // --- transaction contention: 10 concurrent increments --------------------
  try {
    await gateway.setDoc('$base/counters/c1', {'n': 0});
    await Future.wait(List.generate(10, (_) {
      return gateway.runTransaction<void>((tx) async {
        final doc = await tx.get('$base/counters/c1');
        final n = (doc?['n'] as int? ?? 0) + 1;
        tx.set('$base/counters/c1', {'n': n});
      });
    }));
    final after = await gateway.getDoc('$base/counters/c1');
    record(
      'b3-transaction-contention',
      after?['n'] == 10,
      '10 concurrent transactional increments -> n=${after?['n']} (expect 10; '
      'anything less means lost updates, i.e. transactions are not real)',
    );
  } catch (e) {
    record('b3-transaction-contention', false, 'threw: $e');
  }

  // --- (c) the data is in the EMULATOR: read it back over emulator REST ---
  try {
    // `Bearer owner` is the emulator's admin convention (skips rules) — the
    // emulator loads the repo's hardened firestore.rules, so an anonymous
    // REST read is correctly rejected with 403.
    final rest = await http.get(
      Uri.parse(
        'http://$emulatorHost/v1/projects/$projectId/databases/(default)/'
        'documents/spike_runs/$runId',
      ),
      headers: {'authorization': 'Bearer owner'},
    );
    final ok = rest.statusCode == 200 &&
        rest.body.contains('"hello"') &&
        rest.body.contains('emulator');
    record(
      'c1-data-in-emulator',
      ok,
      'emulator REST GET spike_runs/$runId -> HTTP ${rest.statusCode} '
      '(document fields visible: $ok)',
    );
  } catch (e) {
    record('c1-data-in-emulator', false, 'threw: $e');
  }

  await app.close();

  final failed = results.values.where((v) => v == 'FAIL').length;
  stdout.writeln('---');
  stdout.writeln(
    'spike_firestore_emulator: ${results.length} checks, $failed FAIL '
    '(${results.entries.map((e) => '${e.key}=${e.value}').join(', ')})',
  );
  exitCode = failed == 0 ? 0 : 1;
}
