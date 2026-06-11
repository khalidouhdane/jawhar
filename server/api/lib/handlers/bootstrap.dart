import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../config.dart';

/// `GET /v1/me/bootstrap` (authenticated) — Wave 2 shape (roadmap §5 #2,
/// scoped to what has real backing state today): the client-facing sync
/// configuration. The full hydration payload (profiles, settings, progress,
/// plans, cards) joins in Phase 4/5 when the server owns that state.
///
/// `writePath` is the Phase 4 per-user write-path flag, plumbed now and
/// hard-wired to env config (`legacy`) until the facts endpoint exists.
Handler bootstrapHandler(Config config) {
  return (Request request) {
    return Response.ok(
      jsonEncode({
        'minSupportedBuild': config.minSupportedBuild,
        'datasetEpoch': config.datasetEpoch,
        'writePath': config.writePath,
        'modelId': config.modelId,
        'serverTime': DateTime.now().toUtc().toIso8601String(),
      }),
      headers: const {'content-type': 'application/json'},
    );
  };
}
