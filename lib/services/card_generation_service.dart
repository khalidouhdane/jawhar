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

    // Split budget across types proportionally
    final nvBudget = (budget * 0.4).ceil();   // ~40% Next Verse
    final sdBudget = (budget * 0.4).ceil();   // ~40% Surah Detective
    final mdBudget = budget - nvBudget - sdBudget; // remainder Mutashabihat

    created += await _generateNextVerseCards(profileId, verses, random, max: nvBudget);
    created += await _generateSurahDetectiveCards(profileId, verses, random, max: sdBudget);
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
}

class _VerseRef {
  final int surah;
  final int verse;
  final int page;
  const _VerseRef(this.surah, this.verse, this.page);
}
