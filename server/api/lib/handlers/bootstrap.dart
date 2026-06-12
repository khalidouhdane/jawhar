import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../config.dart';
import '../gateway/firestore_gateway.dart';
import '../middleware/auth.dart';
import '../store/legacy_docs.dart';

/// The two write-path values the Phase 4 flag can take (roadmap §8 Phase 4
/// task 4): `legacy` = client keeps its direct-Firestore CloudSyncService
/// writer; `facts` = client writes through `POST /v1/me/facts` only.
const Set<String> kWritePaths = {'legacy', 'facts'};

/// `GET /v1/me/bootstrap` (authenticated) — Wave 2 shape (roadmap §5 #2,
/// scoped to what has real backing state today): the client-facing sync
/// configuration. The full hydration payload (profiles, settings, progress,
/// plans, cards) joins in Phase 5.
///
/// `writePath` is the Phase 4 PER-USER write-path flag — the R2 instant
/// rollback lever. Resolution order:
/// 1. `users/{uid}/meta/server.writePath` when it holds a valid value —
///    a SERVER-ONLY doc (rules allow clients only `meta/settings` and
///    `meta/streak`), flipped via `POST /v1/admin/users/{uid}/writePath`
///    or directly in the Firestore console;
/// 2. else the fleet default from env `WRITE_PATH` (`legacy`).
Handler bootstrapHandler(Config config, {FirestoreGateway? gateway}) {
  return (Request request) async {
    var writePath = config.writePath;
    if (gateway != null) {
      final serverMeta =
          await gateway.getDoc(UserPaths.serverMetaDoc(request.uid));
      final perUser = serverMeta?['writePath'];
      if (perUser is String && kWritePaths.contains(perUser)) {
        writePath = perUser;
      }
    }
    return Response.ok(
      jsonEncode({
        'minSupportedBuild': config.minSupportedBuild,
        'datasetEpoch': config.datasetEpoch,
        'writePath': writePath,
        'modelId': config.modelId,
        'serverTime': DateTime.now().toUtc().toIso8601String(),
      }),
      headers: const {'content-type': 'application/json'},
    );
  };
}
