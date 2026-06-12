/// Strict, bounds-checked JSON field readers for the `/v1` wire types.
///
/// Unlike [PersistedDataParser] (which heals locally persisted data with
/// fallbacks), wire parsing REJECTS malformed input by throwing
/// [FormatException] with a field path — a malformed fact must become a
/// poisoned outbox row / `422`, never silently coerced data (roadmap §5
/// idempotency & error rules).
library;

/// Strict JSON readers. Every method throws [FormatException] naming the
/// offending field on invalid input.
class WireCodec {
  WireCodec._();

  /// RFC-4122 UUID (any version digit accepted; the contract mandates v4
  /// from clients, but replayed historical ids are never rejected on
  /// version alone).
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}'
    r'-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Client-local calendar date, `YYYY-MM-DD`.
  static final RegExp _localDatePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  /// Identifier charset for values that become Firestore document-path
  /// segments (card ids, profile ids): covers RFC-4122 UUIDs and legacy
  /// deterministic ids like `p1_nv_3_21`. Critically excludes `/`, which
  /// would change the Firestore path depth server-side and turn the write
  /// into a permanently-retrying SDK ArgumentError.
  static final RegExp _idPattern = RegExp(r'^[A-Za-z0-9_:.-]{1,64}$');

  /// Whether [value] is safe to interpolate into a Firestore document path
  /// segment (see [requireId]).
  static bool isSafeId(String value) => _idPattern.hasMatch(value);

  static Never _fail(String field, String reason) =>
      throw FormatException('Invalid "$field": $reason');

  /// The map for a nested object field.
  static Map<String, dynamic> requireMap(
    Map<String, dynamic> json,
    String field,
  ) {
    final value = json[field];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    _fail(field, 'expected an object, got ${value.runtimeType}');
  }

  /// A non-null string; optionally non-empty; optionally length-capped
  /// (oversize payloads must poison, not retry forever against Firestore
  /// write limits).
  static String requireString(
    Map<String, dynamic> json,
    String field, {
    bool allowEmpty = false,
    int? maxLength,
  }) {
    final value = json[field];
    if (value is! String) {
      _fail(field, 'expected a string, got ${value.runtimeType}');
    }
    if (!allowEmpty && value.isEmpty) _fail(field, 'must not be empty');
    if (maxLength != null && value.length > maxLength) {
      _fail(field, 'must be <= $maxLength characters');
    }
    return value;
  }

  /// A path-safe identifier string (see [isSafeId]): 1-64 chars of
  /// `[A-Za-z0-9_:.-]`. Used for every value the server interpolates into a
  /// Firestore document path (cardId, profileId).
  static String requireId(Map<String, dynamic> json, String field) {
    final value = requireString(json, field);
    if (!isSafeId(value)) {
      _fail(
        field,
        'expected 1-64 chars of [A-Za-z0-9_:.-] (path-safe identifier)',
      );
    }
    return value;
  }

  /// A nullable string (absent or `null` → null).
  static String? optionalString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null) return null;
    if (value is! String) {
      _fail(field, 'expected a string or null, got ${value.runtimeType}');
    }
    return value;
  }

  /// An integer within optional inclusive bounds. Accepts JSON numbers only
  /// when they are exactly integral.
  static int requireInt(
    Map<String, dynamic> json,
    String field, {
    int? min,
    int? max,
  }) {
    final value = json[field];
    final int parsed;
    if (value is int) {
      parsed = value;
    } else if (value is num && value == value.truncate()) {
      parsed = value.toInt();
    } else {
      _fail(field, 'expected an integer, got ${value.runtimeType}');
    }
    if (min != null && parsed < min) _fail(field, 'must be >= $min');
    if (max != null && parsed > max) _fail(field, 'must be <= $max');
    return parsed;
  }

  /// A nullable bounded integer.
  static int? optionalInt(
    Map<String, dynamic> json,
    String field, {
    int? min,
    int? max,
  }) {
    if (json[field] == null) return null;
    return requireInt(json, field, min: min, max: max);
  }

  /// A finite double (ints accepted and widened).
  static double requireDouble(
    Map<String, dynamic> json,
    String field, {
    double? min,
    double? max,
  }) {
    final value = json[field];
    if (value is! num) {
      _fail(field, 'expected a number, got ${value.runtimeType}');
    }
    final parsed = value.toDouble();
    if (!parsed.isFinite) _fail(field, 'must be finite');
    if (min != null && parsed < min) _fail(field, 'must be >= $min');
    if (max != null && parsed > max) _fail(field, 'must be <= $max');
    return parsed;
  }

  /// A boolean.
  static bool requireBool(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is! bool) {
      _fail(field, 'expected a boolean, got ${value.runtimeType}');
    }
    return value;
  }

  /// An RFC-4122 UUID string.
  static String requireUuid(Map<String, dynamic> json, String field) {
    final value = requireString(json, field);
    if (!_uuidPattern.hasMatch(value)) {
      _fail(field, 'expected an RFC-4122 UUID');
    }
    return value;
  }

  /// An ISO-8601 instant with an EXPLICIT UTC designator (`Z` / `+00:00`).
  ///
  /// Fields named `*Utc` carry instants; a timezone-naive value here would
  /// silently shift by the parser host's timezone, so it is rejected.
  static DateTime requireUtcInstant(Map<String, dynamic> json, String field) {
    final raw = requireString(json, field);
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) _fail(field, 'expected an ISO-8601 instant');
    if (!parsed.isUtc) {
      _fail(field, 'instant must carry an explicit UTC offset (…Z)');
    }
    return parsed;
  }

  /// A client-local calendar date string, strict `YYYY-MM-DD`, validated as
  /// a real calendar date. Returned verbatim (the string itself is the
  /// canonical wire value — roadmap §5 date semantics).
  static String requireLocalDate(Map<String, dynamic> json, String field) {
    final raw = requireString(json, field);
    if (!_localDatePattern.hasMatch(raw)) {
      _fail(field, 'expected YYYY-MM-DD');
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) _fail(field, 'not a valid calendar date');
    // Reject normalized overflow such as 2026-02-31 → 2026-03-03.
    final canonical =
        '${parsed.year.toString().padLeft(4, '0')}-'
        '${parsed.month.toString().padLeft(2, '0')}-'
        '${parsed.day.toString().padLeft(2, '0')}';
    if (canonical != raw) _fail(field, 'not a valid calendar date');
    return raw;
  }

  /// A list of bounded integers. Out-of-bounds elements are REJECTED, not
  /// dropped (contrast with `PersistedDataParser.intList`, which heals
  /// local persistence). Duplicates and order are preserved. [maxLength]
  /// bounds the LIST length — page lists feed one Firestore write per
  /// element, and an unbounded list can push a transaction over the
  /// 500-mutation commit limit (deterministic failure miscast as retryable).
  static List<int> requireIntList(
    Map<String, dynamic> json,
    String field, {
    int? min,
    int? max,
    int? maxLength,
    bool allowMissing = false,
  }) {
    final value = json[field];
    if (value == null && allowMissing) return const [];
    if (value is! List) {
      _fail(field, 'expected an array, got ${value.runtimeType}');
    }
    if (maxLength != null && value.length > maxLength) {
      _fail(field, 'must have <= $maxLength elements');
    }
    final result = <int>[];
    for (var i = 0; i < value.length; i++) {
      final element = value[i];
      final int parsed;
      if (element is int) {
        parsed = element;
      } else if (element is num && element == element.truncate()) {
        parsed = element.toInt();
      } else {
        _fail('$field[$i]', 'expected an integer');
      }
      if (min != null && parsed < min) _fail('$field[$i]', 'must be >= $min');
      if (max != null && parsed > max) _fail('$field[$i]', 'must be <= $max');
      result.add(parsed);
    }
    return result;
  }

  /// An enum decoded from its wire integer index (matching today's
  /// `firestore.rules` integer bounds, e.g. rating 0–3).
  static T requireEnumIndex<T extends Enum>(
    Map<String, dynamic> json,
    String field,
    List<T> values,
  ) {
    final index = requireInt(json, field, min: 0, max: values.length - 1);
    return values[index];
  }

  /// A nullable enum decoded from its wire integer index.
  static T? optionalEnumIndex<T extends Enum>(
    Map<String, dynamic> json,
    String field,
    List<T> values,
  ) {
    if (json[field] == null) return null;
    return requireEnumIndex(json, field, values);
  }

  /// Formats an instant for the wire: ISO-8601 UTC with `Z`.
  static String encodeUtcInstant(DateTime instant) =>
      instant.toUtc().toIso8601String();
}
