import 'dart:convert';

/// Mode for defining the daily werd.
enum WerdMode {
  /// Read a fixed range of pages (e.g., pages 50–60).
  fixedRange,

  /// Read a set number of pages each day, advancing through the Quran.
  dailyPages,
}

/// Configuration and progress for a user's daily recitation (werd).
class WerdConfig {
  final WerdMode mode;
  final int startPage;
  final int endPage;
  final int pagesPerDay;
  final int pagesReadToday;
  final DateTime lastResetDate;
  final bool isEnabled;

  const WerdConfig({
    required this.mode,
    required this.startPage,
    required this.endPage,
    required this.pagesPerDay,
    this.pagesReadToday = 0,
    required this.lastResetDate,
    this.isEnabled = true,
  });

  /// Total pages in the configured range.
  int get totalPages => (endPage - startPage + 1).clamp(1, 604);

  /// Today's target page count.
  int get todayTarget => mode == WerdMode.fixedRange ? totalPages : pagesPerDay;

  /// Progress fraction for the current day (0.0–1.0).
  double get progress =>
      todayTarget > 0 ? (pagesReadToday / todayTarget).clamp(0.0, 1.0) : 0.0;

  /// Whether today's target has been reached.
  bool get isComplete => pagesReadToday >= todayTarget;

  /// Returns a copy with updated fields.
  WerdConfig copyWith({
    WerdMode? mode,
    int? startPage,
    int? endPage,
    int? pagesPerDay,
    int? pagesReadToday,
    DateTime? lastResetDate,
    bool? isEnabled,
  }) {
    return WerdConfig(
      mode: mode ?? this.mode,
      startPage: startPage ?? this.startPage,
      endPage: endPage ?? this.endPage,
      pagesPerDay: pagesPerDay ?? this.pagesPerDay,
      pagesReadToday: pagesReadToday ?? this.pagesReadToday,
      lastResetDate: lastResetDate ?? this.lastResetDate,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'mode': mode.index,
    'startPage': startPage,
    'endPage': endPage,
    'pagesPerDay': pagesPerDay,
    'pagesReadToday': pagesReadToday,
    'lastResetDate': lastResetDate.toIso8601String(),
    'isEnabled': isEnabled,
  };

  factory WerdConfig.fromJson(Map<String, dynamic> json) {
    return WerdConfig(
      mode: WerdMode.values[json['mode'] as int],
      startPage: json['startPage'] as int,
      endPage: json['endPage'] as int,
      pagesPerDay: json['pagesPerDay'] as int,
      pagesReadToday: json['pagesReadToday'] as int? ?? 0,
      lastResetDate: DateTime.parse(json['lastResetDate'] as String),
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  /// Serialize to a JSON string for SharedPreferences.
  String encode() => jsonEncode(toJson());

  /// Deserialize from a JSON string.
  static WerdConfig? decode(String? source) {
    if (source == null || source.isEmpty) return null;
    try {
      return WerdConfig.fromJson(jsonDecode(source) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
