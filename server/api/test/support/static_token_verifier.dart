import 'package:jawhar_api/middleware/auth.dart';

/// Deterministic [TokenVerifier] for tests and contract tests: maps known
/// opaque token strings to identities, rejects everything else. Lives under
/// test/ — it is not part of the shipped library, so the production image
/// cannot reference it (roadmap §4.3).
class StaticTokenVerifier implements TokenVerifier {
  StaticTokenVerifier(this._identities);

  final Map<String, VerifiedToken> _identities;

  /// Tokens this verifier was asked to check, in order (for assertions).
  final List<String> seenTokens = [];

  @override
  Future<VerifiedToken> verify(String idToken) async {
    seenTokens.add(idToken);
    final identity = _identities[idToken];
    if (identity == null) {
      throw TokenVerificationException('Unknown test token.');
    }
    return identity;
  }
}
