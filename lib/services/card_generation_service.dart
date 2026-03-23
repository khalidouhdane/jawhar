import 'dart:math';
import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_app/models/flashcard_models.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/services/hifz_database_service.dart';

/// Generates flashcards from memorized content.
/// Creates verse-specific cards using the quran package for offline text.
class CardGenerationService {
  final HifzDatabaseService _db;

  CardGenerationService(this._db);

  /// Max cards to keep in the due queue at any time.
  static const int _maxDueCards = 30;

  /// Generate new flashcards for a profile based on their progress.
  /// Skips generation if enough due cards already exist.
  Future<int> generateCards(String profileId) async {
    // Check if there are already enough due cards (use stats count, not limited query)
    final stats = await _db.getFlashcardStats(profileId);
    final dueCount = (stats['due'] as num?)?.toInt() ?? 0;
    if (dueCount >= _maxDueCards) {
      debugPrint('[Flashcard Gen] Already $dueCount due cards — skipping generation');
      return 0;
    }

    final progress = await _db.getAllPageProgress(profileId);
    debugPrint('[Flashcard Gen] Profile: $profileId, progress: ${progress.length} pages');
    if (progress.isEmpty) return 0;

    // Collect all verses from eligible pages
    final verses = <_VerseRef>[];
    for (final entry in progress.entries) {
      final status = entry.value.status;
      if (status == PageStatus.learning ||
          status == PageStatus.memorized ||
          status == PageStatus.reviewing) {
        final pageData = quran.getPageData(entry.key);
        for (final section in pageData) {
          final surah = section['surah'] as int;
          final start = section['start'] as int;
          final end = section['end'] as int;
          for (int v = start; v <= end; v++) {
            verses.add(_VerseRef(surah, v, entry.key));
          }
        }
      }
    }

    debugPrint('[Flashcard Gen] Total eligible verses: ${verses.length}');
    if (verses.isEmpty) return 0;

    final random = Random();
    int created = 0;
    final budget = _maxDueCards - dueCount;

    // Split budget across 6 types
    final perType = (budget / 6).ceil();
    final nvBudget = perType;
    final sdBudget = perType;
    final vcBudget = perType;
    final pvBudget = perType;
    final csBudget = perType;
    final mdBudget = (budget - nvBudget - sdBudget - vcBudget - pvBudget - csBudget).clamp(0, budget);

    created += await _generateNextVerseCards(profileId, verses, random, max: nvBudget);
    created += await _generateSurahDetectiveCards(profileId, verses, random, max: sdBudget);
    created += await _generateVerseCompletionCards(profileId, verses, random, max: vcBudget);
    created += await _generatePreviousVerseCards(profileId, verses, random, max: pvBudget);
    created += await _generateConnectSequenceCards(profileId, verses, random, max: csBudget);
    created += await _generateMutashabihatDuelCards(profileId, max: mdBudget);

    debugPrint('[Flashcard Gen] Total created: $created new flashcards');
    return created;
  }

  /// Next Verse: show a verse, ask what comes after it.
  Future<int> _generateNextVerseCards(
    String profileId,
    List<_VerseRef> verses,
    Random random, {
    int max = 10,
  }) async {
    if (max <= 0) return 0;
    int created = 0;
    // Pick up to max random verses (not the last verse of a surah)
    final eligible = verses.where((v) => v.verse < quran.getVerseCount(v.surah)).toList();
    if (eligible.isEmpty) return 0;

    eligible.shuffle(random);
    final sampleSize = min(max, eligible.length);

    for (int i = 0; i < sampleSize; i++) {
      final v = eligible[i];
      final verseKey = '${v.surah}:${v.verse}';

      final exists = await _db.flashcardExists(
        profileId, verseKey, FlashcardType.nextVerse,
      );
      if (exists) continue;

      final questionText = quran.getVerse(v.surah, v.verse);
      final answerText = quran.getVerse(v.surah, v.verse + 1);
      final surahName = quran.getSurahNameArabic(v.surah);

      final card = Flashcard(
        id: '${profileId}_nv_${v.surah}_${v.verse}_${DateTime.now().millisecondsSinceEpoch}',
        type: FlashcardType.nextVerse,
        profileId: profileId,
        verseKey: verseKey,
        questionData: {
          'instruction': 'ما الآية التالية؟',
          'verseText': questionText,
          'surah': v.surah,
          'verse': v.verse,
          'surahName': surahName,
          'page': v.page,
        },
        answerData: {
          'verseText': answerText,
          'surah': v.surah,
          'verse': v.verse + 1,
          'surahName': surahName,
        },
        dueDate: DateTime.now(),
      );

      await _db.saveFlashcard(card);
      created++;
      if (created >= max) break;
    }
    return created;
  }

  /// Surah Detective: show a verse, ask which surah it's from.
  Future<int> _generateSurahDetectiveCards(
    String profileId,
    List<_VerseRef> verses,
    Random random, {
    int max = 8,
  }) async {
    if (max <= 0) return 0;
    int created = 0;
    final shuffled = List.of(verses)..shuffle(random);
    final sampleSize = min(max, shuffled.length);

    for (int i = 0; i < sampleSize; i++) {
      final v = shuffled[i];
      final verseKey = '${v.surah}:${v.verse}';

      final exists = await _db.flashcardExists(
        profileId, verseKey, FlashcardType.surahDetective,
      );
      if (exists) continue;

      final verseText = quran.getVerse(v.surah, v.verse);
      final surahName = quran.getSurahNameArabic(v.surah);
      final surahNameEn = quran.getSurahNameEnglish(v.surah);

      final card = Flashcard(
        id: '${profileId}_sd_${v.surah}_${v.verse}_${DateTime.now().millisecondsSinceEpoch + i}',
        type: FlashcardType.surahDetective,
        profileId: profileId,
        verseKey: verseKey,
        questionData: {
          'instruction': 'من أي سورة هذه الآية؟',
          'verseText': verseText,
          'surah': v.surah,
          'verse': v.verse,
          'page': v.page,
        },
        answerData: {
          'surah': v.surah,
          'verse': v.verse,
          'surahName': surahName,
          'surahNameEn': surahNameEn,
          'surahNumber': v.surah,
        },
        dueDate: DateTime.now(),
      );

      await _db.saveFlashcard(card);
      created++;
      if (created >= max) break;
    }
    return created;
  }

  /// Mutashabihat Duel: from imported mutashabihat dataset.
  Future<int> _generateMutashabihatDuelCards(String profileId, {int max = 5}) async {
    if (max <= 0) return 0;
    int created = 0;
    final groups = await _db.getMutashabihatByStatus(
      MutashabihatStatus.needsPractice,
    );

    for (final group in groups) {
      if (group.similarVerses.isEmpty) continue;

      final verseKey = group.sourceVerseKey;
      final exists = await _db.flashcardExists(
        profileId, verseKey, FlashcardType.mutashabihatDuel,
      );
      if (exists) continue;

      // Parse verse keys to get actual text
      final sourceparts = group.sourceVerseKey.split(':');
      String sourceText = '';
      String similarText = '';
      try {
        final sSurah = int.parse(sourceparts[0]);
        final sVerse = int.parse(sourceparts[1]);
        sourceText = quran.getVerse(sSurah, sVerse);
        final simParts = group.similarVerses.first.verseKey.split(':');
        final simSurah = int.parse(simParts[0]);
        final simVerse = int.parse(simParts[1]);
        similarText = quran.getVerse(simSurah, simVerse);
      } catch (_) {
        continue;
      }

      final card = Flashcard(
        id: '${profileId}_md_${group.groupId}_${DateTime.now().millisecondsSinceEpoch}',
        type: FlashcardType.mutashabihatDuel,
        profileId: profileId,
        verseKey: verseKey,
        questionData: {
          'groupId': group.groupId,
          'sourceVerseKey': group.sourceVerseKey,
          'similarVerseKey': group.similarVerses.first.verseKey,
          'instruction': 'أي الآيتين من السورة الصحيحة؟',
          'sourceText': sourceText,
          'similarText': similarText,
        },
        answerData: {
          'correctVerseKey': group.sourceVerseKey,
          'groupId': group.groupId,
        },
        dueDate: DateTime.now(),
      );

      await _db.saveFlashcard(card);
      created++;

      if (created >= 5) break;
    }
    return created;
  }

  /// Verse Completion: show partial verse with blanked words, ask user to recall.
  Future<int> _generateVerseCompletionCards(
    String profileId,
    List<_VerseRef> verses,
    Random random, {
    int max = 6,
  }) async {
    if (max <= 0) return 0;
    int created = 0;
    // Need verses with at least 5 words to blank meaningfully
    final eligible = verses.where((v) {
      final text = quran.getVerse(v.surah, v.verse);
      return text.split(' ').length >= 5;
    }).toList();
    if (eligible.isEmpty) return 0;

    eligible.shuffle(random);
    final sampleSize = min(max, eligible.length);

    for (int i = 0; i < sampleSize; i++) {
      final v = eligible[i];
      final verseKey = '${v.surah}:${v.verse}';

      final exists = await _db.flashcardExists(
        profileId, verseKey, FlashcardType.verseCompletion,
      );
      if (exists) continue;

      final fullText = quran.getVerse(v.surah, v.verse);
      final words = fullText.split(' ');
      // Blank out last ~30% of words
      final visibleCount = (words.length * 0.7).round().clamp(2, words.length - 1);
      final visibleText = words.sublist(0, visibleCount).join(' ');
      final blankedText = '$visibleText ${'___ ' * (words.length - visibleCount)}'.trim();
      final surahName = quran.getSurahNameArabic(v.surah);

      final card = Flashcard(
        id: '${profileId}_vc_${v.surah}_${v.verse}_${DateTime.now().millisecondsSinceEpoch + i}',
        type: FlashcardType.verseCompletion,
        profileId: profileId,
        verseKey: verseKey,
        questionData: {
          'instruction': 'أكمل الآية',
          'blankedText': blankedText,
          'surah': v.surah,
          'verse': v.verse,
          'surahName': surahName,
          'page': v.page,
        },
        answerData: {
          'verseText': fullText,
          'surah': v.surah,
          'verse': v.verse,
          'surahName': surahName,
        },
        dueDate: DateTime.now(),
      );

      await _db.saveFlashcard(card);
      created++;
      if (created >= max) break;
    }
    return created;
  }

  /// Previous Verse: show a verse, ask what came before it.
  Future<int> _generatePreviousVerseCards(
    String profileId,
    List<_VerseRef> verses,
    Random random, {
    int max = 6,
  }) async {
    if (max <= 0) return 0;
    int created = 0;
    // Must not be the first verse of a surah
    final eligible = verses.where((v) => v.verse > 1).toList();
    if (eligible.isEmpty) return 0;

    eligible.shuffle(random);
    final sampleSize = min(max, eligible.length);

    for (int i = 0; i < sampleSize; i++) {
      final v = eligible[i];
      final verseKey = '${v.surah}:${v.verse}';

      final exists = await _db.flashcardExists(
        profileId, verseKey, FlashcardType.previousVerse,
      );
      if (exists) continue;

      final questionText = quran.getVerse(v.surah, v.verse);
      final answerText = quran.getVerse(v.surah, v.verse - 1);
      final surahName = quran.getSurahNameArabic(v.surah);

      final card = Flashcard(
        id: '${profileId}_pv_${v.surah}_${v.verse}_${DateTime.now().millisecondsSinceEpoch + i}',
        type: FlashcardType.previousVerse,
        profileId: profileId,
        verseKey: verseKey,
        questionData: {
          'instruction': 'ما الآية السابقة؟',
          'verseText': questionText,
          'surah': v.surah,
          'verse': v.verse,
          'surahName': surahName,
          'page': v.page,
        },
        answerData: {
          'verseText': answerText,
          'surah': v.surah,
          'verse': v.verse - 1,
          'surahName': surahName,
        },
        dueDate: DateTime.now(),
      );

      await _db.saveFlashcard(card);
      created++;
      if (created >= max) break;
    }
    return created;
  }

  /// Connect Sequence: scramble 3 consecutive verses, user reorders.
  Future<int> _generateConnectSequenceCards(
    String profileId,
    List<_VerseRef> verses,
    Random random, {
    int max = 4,
  }) async {
    if (max <= 0) return 0;
    int created = 0;

    // Group verses by surah so we can pick consecutive sequences
    final bySurah = <int, List<_VerseRef>>{};
    for (final v in verses) {
      bySurah.putIfAbsent(v.surah, () => []).add(v);
    }

    // Find surahs with at least 3 consecutive memorized verses
    final candidates = <List<_VerseRef>>[];
    for (final entry in bySurah.entries) {
      final sorted = List<_VerseRef>.from(entry.value)
        ..sort((a, b) => a.verse.compareTo(b.verse));
      for (int i = 0; i < sorted.length - 2; i++) {
        if (sorted[i].verse + 1 == sorted[i + 1].verse &&
            sorted[i + 1].verse + 1 == sorted[i + 2].verse) {
          candidates.add([sorted[i], sorted[i + 1], sorted[i + 2]]);
        }
      }
    }

    if (candidates.isEmpty) return 0;
    candidates.shuffle(random);

    for (final seq in candidates) {
      if (created >= max) break;
      final anchorKey = '${seq[0].surah}:${seq[0].verse}-${seq[2].verse}';

      final exists = await _db.flashcardExists(
        profileId, anchorKey, FlashcardType.connectSequence,
      );
      if (exists) continue;

      final surahName = quran.getSurahNameArabic(seq[0].surah);
      // Build verse data in correct order
      final correctOrder = seq.map((v) => {
        'surah': v.surah,
        'verse': v.verse,
        'text': quran.getVerse(v.surah, v.verse),
      }).toList();

      // Create a shuffled index order
      final indices = [0, 1, 2];
      indices.shuffle(random);

      final card = Flashcard(
        id: '${profileId}_cs_${seq[0].surah}_${seq[0].verse}_${DateTime.now().millisecondsSinceEpoch}',
        type: FlashcardType.connectSequence,
        profileId: profileId,
        verseKey: anchorKey,
        questionData: {
          'instruction': '\u0631\u062a\u0628 \u0627\u0644\u0622\u064a\u0627\u062a',
          'surahName': surahName,
          'surah': seq[0].surah,
          'page': seq[0].page,
          'shuffledIndices': indices,
          'verses': correctOrder,
        },
        answerData: {
          'correctOrder': [0, 1, 2],
          'verses': correctOrder,
        },
        dueDate: DateTime.now(),
      );

      await _db.saveFlashcard(card);
      created++;
    }
    return created;
  }
}

class _VerseRef {
  final int surah;
  final int verse;
  final int page;
  const _VerseRef(this.surah, this.verse, this.page);
}
