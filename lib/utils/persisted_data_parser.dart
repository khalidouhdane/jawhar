// Moved to packages/hifz_core (the shared models' SQLite/JSON parsing
// depends on it on both tiers). This shim keeps every existing
// `package:quran_app/utils/persisted_data_parser.dart` import working
// unchanged.

export 'package:hifz_core/hifz_core.dart' show PersistedDataParser;
