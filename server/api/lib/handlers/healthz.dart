import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../config.dart';

/// `GET /health` (and `/healthz` for local use) — liveness + deployed-SHA
/// drift detection (roadmap §5 #1):
/// {status, gitSha, modelId, minSupportedBuild, datasetEpoch}.
///
/// Public path is `/health`, not the roadmap's `/healthz`: Cloud Run's
/// frontend swallows `/healthz` on *.run.app hosts (returns a Google 404
/// without forwarding), verified live 2026-06-12.
Handler healthzHandler(Config config) {
  return (Request request) {
    return Response.ok(
      jsonEncode({
        'status': 'ok',
        'gitSha': config.gitSha,
        'modelId': config.modelId,
        'minSupportedBuild': config.minSupportedBuild,
        'datasetEpoch': config.datasetEpoch,
      }),
      headers: const {'content-type': 'application/json'},
    );
  };
}
