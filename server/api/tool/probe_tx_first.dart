import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:jawhar_api/gateway/firestore_gateway.dart';

Future<void> main() async {
  final app = FirebaseApp.initializeApp(
    options: const AppOptions(projectId: 'demo-probe-tx'),
  );
  final gateway = FirestoreGateway(app.firestore());
  var callbackRuns = 0;
  var getCompleted = 0;
  try {
    await gateway.runTransaction((tx) async {
      callbackRuns++;
      final doc = await tx.get('probe/x');
      getCompleted++;
      tx.set('probe/x', {'n': (doc?['n'] as int? ?? 0) + 1});
    });
    print('PROBE: first-RPC transaction SUCCEEDED');
  } catch (e) {
    print('PROBE: first-RPC tx FAILED (callbackRuns=$callbackRuns, getCompleted=$getCompleted): $e');
  }
  final after = await gateway.getDoc('probe/x');
  print('PROBE: doc after failed tx = $after (null/absent means nothing applied)');
  await gateway.runTransaction((tx) async {
    final doc = await tx.get('probe/x');
    tx.set('probe/x', {'n': (doc?['n'] as int? ?? 0) + 1});
  });
  final end = await gateway.getDoc('probe/x');
  print('PROBE: doc after retry tx = $end (n=1 means failed attempt applied nothing)');
  await app.close();
}
