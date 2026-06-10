class PersistedDataParser {
  static int intValue(Object? value, {required int fallback}) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double doubleValue(Object? value, {required double fallback}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static T enumValue<T>(
    List<T> values,
    Object? rawValue, {
    required T fallback,
  }) {
    final index = intValue(rawValue, fallback: values.indexOf(fallback));
    if (index < 0 || index >= values.length) return fallback;
    return values[index];
  }

  static DateTime requiredDate(Object? value, {required String field}) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) {
      throw FormatException('Invalid persisted date for $field');
    }
    return parsed;
  }

  static DateTime? nullableDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static List<int> intList(
    Object? value, {
    int? minimum,
    int? maximum,
    List<int> fallback = const [],
  }) {
    final rawValues = switch (value) {
      String text when text.trim().isNotEmpty => text.split(','),
      Iterable<Object?> values => values,
      _ => const <Object?>[],
    };
    if (rawValues.isEmpty) return List<int>.from(fallback);

    final parsed = <int>{};
    for (final raw in rawValues) {
      final candidate = int.tryParse(raw.toString().trim());
      if (candidate == null) continue;
      if (minimum != null && candidate < minimum) continue;
      if (maximum != null && candidate > maximum) continue;
      parsed.add(candidate);
    }
    return parsed.toList();
  }
}
