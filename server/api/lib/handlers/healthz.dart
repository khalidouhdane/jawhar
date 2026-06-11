import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../config.dart';

/// `GET /healthz` — liveness + deployed-SHA drift detection (roadmap §5 #1).
///
/// Wave 1 shape: {status, gitSha, modelId}. `minSupportedBuild` and
/// `datasetEpoch` join in Wave 2 when they have real backing state.
Handler healthzHandler(Config config) {
  return (Request request) {
    return Response.ok(
      jsonEncode({
        'status': 'ok',
        'gitSha': config.gitSha,
        'modelId': config.modelId,
      }),
      headers: const {'content-type': 'application/json'},
    );
  };
}
