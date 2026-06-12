import 'dart:convert';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';

/// Default request-body cap: far above any legitimate `/v1` payload (a
/// 1000-fact batch of ordinary facts is well under 1 MB) but small enough
/// that an authenticated client cannot post multi-MB blob batches that fail
/// Firestore's per-document limits one expensive transaction at a time.
const int kDefaultMaxBodyBytes = 5 * 1024 * 1024;

/// Rejects request bodies larger than [maxBytes] with `413` (§5 error
/// envelope, `retryable:false` — a too-large body never shrinks on retry).
///
/// Sits INSIDE the `/v1` auth + rate-limit pipeline on purpose:
/// unauthenticated junk is 401'd from headers alone without ever buffering
/// a body, and per-uid rate limiting has already metered the caller. Bodies
/// at or under the cap are buffered and passed along unchanged (handlers
/// call `readAsString()` anyway), so declared AND chunked/undeclared
/// lengths are both enforced.
Middleware bodySizeLimit({int maxBytes = kDefaultMaxBodyBytes}) {
  return (Handler inner) {
    return (Request request) async {
      final declared = request.contentLength;
      if (declared != null && declared > maxBytes) {
        return _tooLarge(maxBytes);
      }
      if (declared == 0) return inner(request);

      final builder = BytesBuilder(copy: false);
      await for (final chunk in request.read()) {
        builder.add(chunk);
        if (builder.length > maxBytes) return _tooLarge(maxBytes);
      }
      return inner(request.change(body: builder.takeBytes()));
    };
  };
}

Response _tooLarge(int maxBytes) => Response(
      413,
      body: jsonEncode({
        'error': {
          'code': 'payload-too-large',
          'message': 'Request body exceeds $maxBytes bytes.',
          'retryable': false,
        },
      }),
      headers: const {'content-type': 'application/json'},
    );
