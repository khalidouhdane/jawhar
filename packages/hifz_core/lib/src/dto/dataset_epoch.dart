/// Server data-generation id (roadmap §5).
///
/// `/health`, `/v1/me/bootstrap`, and every `/v1/me/facts` response carry a
/// `datasetEpoch`. The client persists the last seen value; on mismatch it
/// executes the announced reset policy (wipe local cache + outbox, or
/// wipe-then-rebackfill). This value type exists so both tiers compare
/// epochs the same way and never confuse an epoch with any other string.
final class DatasetEpoch {
  /// Opaque, non-empty server-chosen identifier (e.g. `"e1"`).
  final String value;

  const DatasetEpoch(this.value);

  /// Strict parse: any non-empty string is a valid epoch; everything else
  /// is a [FormatException].
  factory DatasetEpoch.parse(Object? raw) {
    if (raw is! String || raw.isEmpty) {
      throw const FormatException(
        'Invalid "datasetEpoch": expected a non-empty string',
      );
    }
    return DatasetEpoch(raw);
  }

  /// Wire form (plain JSON string).
  String toJson() => value;

  @override
  bool operator ==(Object other) =>
      other is DatasetEpoch && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'DatasetEpoch($value)';
}
