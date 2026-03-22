import 'package:flutter/material.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

/// Data model for a surah introduction.
class SurahIntroData {
  final int id;
  final String nameArabic;
  final String nameEnglish;
  final String meaningOfName;
  final String revelationType; // 'Meccan' or 'Medinan'
  final int versesCount;
  final String summary;
  final List<String> keyThemes;

  const SurahIntroData({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    required this.meaningOfName,
    required this.revelationType,
    required this.versesCount,
    required this.summary,
    required this.keyThemes,
  });
}

/// A thematic overview card shown when starting a new surah.
///
/// Displays surah name, revelation type, key themes, and a brief summary.
/// Designed to set the stage before memorization begins.
///
/// Usage:
/// ```dart
/// SurahIntroCard(
///   surahId: 2,
///   onDismiss: () => setState(() => _showIntro = false),
/// )
/// ```
class SurahIntroCard extends StatelessWidget {
  final int surahId;
  final VoidCallback? onDismiss;

  /// Optional: provide the data directly instead of using the static map.
  final SurahIntroData? data;

  const SurahIntroCard({
    super.key,
    required this.surahId,
    this.onDismiss,
    this.data,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final intro = data ?? surahIntroductions[surahId];

    if (intro == null) {
      return const SizedBox.shrink();
    }

    final isMeccan = intro.revelationType == 'Meccan';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.accentColor.withValues(alpha: 0.08),
                  theme.accentColor.withValues(alpha: 0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                // Surah name
                ExcludeSemantics(
                  child: Text(
                    intro.nameArabic,
                    style: GoogleFonts.amiri(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: theme.accentColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${intro.nameEnglish} — ${intro.meaningOfName}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.primaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                // Badges row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Badge(
                      label: intro.revelationType,
                      icon: isMeccan
                          ? Icons.mosque_outlined
                          : Icons.location_city_outlined,
                      color: isMeccan
                          ? const Color(0xFFD4A373)
                          : const Color(0xFF4DB6AC),
                      theme: theme,
                    ),
                    const SizedBox(width: 8),
                    _Badge(
                      label: '${intro.versesCount} verses',
                      icon: Icons.format_list_numbered,
                      color: theme.accentColor,
                      theme: theme,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Summary
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              intro.summary,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.6,
                color: theme.secondaryText,
              ),
            ),
          ),

          // Key themes
          if (intro.keyThemes.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(
                'Key Themes',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.accentColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: intro.keyThemes.map((t) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: theme.pillBackground,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      t,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: theme.secondaryText,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // Dismiss button
          if (onDismiss != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onDismiss,
                  style: TextButton.styleFrom(
                    backgroundColor: theme.accentColor,
                    foregroundColor: theme.chipSelectedText,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Begin',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final ThemeProvider theme;

  const _Badge({
    required this.label,
    required this.icon,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Curated Surah Introduction Data ──
//
// Static data for the first 20 surahs as a starter. This can be expanded
// incrementally. The data is derived from well-known tafsir introductions.

const Map<int, SurahIntroData> surahIntroductions = {
  1: SurahIntroData(
    id: 1,
    nameArabic: 'الفاتحة',
    nameEnglish: 'Al-Fatihah',
    meaningOfName: 'The Opening',
    revelationType: 'Meccan',
    versesCount: 7,
    summary:
        'The opening chapter of the Quran. A complete prayer that encapsulates the essence of the entire Quran: praising Allah, acknowledging His sovereignty, and seeking guidance on the straight path.',
    keyThemes: ['Praise of Allah', 'Seeking guidance', 'The straight path'],
  ),
  2: SurahIntroData(
    id: 2,
    nameArabic: 'البقرة',
    nameEnglish: 'Al-Baqarah',
    meaningOfName: 'The Cow',
    revelationType: 'Medinan',
    versesCount: 286,
    summary:
        'The longest surah in the Quran. Establishes the laws, principles, and community guidelines for the new Muslim community in Medina. Named after the story of the cow that the Israelites were commanded to sacrifice.',
    keyThemes: [
      'Divine guidance',
      'Legal rulings',
      'Stories of past nations',
      'Ayat al-Kursi',
    ],
  ),
  3: SurahIntroData(
    id: 3,
    nameArabic: 'آل عمران',
    nameEnglish: 'Ali \'Imran',
    meaningOfName: 'The Family of Imran',
    revelationType: 'Medinan',
    versesCount: 200,
    summary:
        'Discusses the family of Imran (the father of Maryam), the birth of Jesus, and the Battle of Uhud. Addresses Christian theology and emphasizes the unity of divine message.',
    keyThemes: [
      'Interfaith dialogue',
      'Battle of Uhud',
      'Steadfastness',
      'Family of Maryam',
    ],
  ),
  4: SurahIntroData(
    id: 4,
    nameArabic: 'النساء',
    nameEnglish: 'An-Nisa',
    meaningOfName: 'The Women',
    revelationType: 'Medinan',
    versesCount: 176,
    summary:
        'Addresses the rights of women, orphans, and family law. Establishes inheritance laws, marriage regulations, and principles of social justice.',
    keyThemes: [
      'Women\'s rights',
      'Inheritance law',
      'Social justice',
      'Family structure',
    ],
  ),
  5: SurahIntroData(
    id: 5,
    nameArabic: 'المائدة',
    nameEnglish: 'Al-Ma\'idah',
    meaningOfName: 'The Table Spread',
    revelationType: 'Medinan',
    versesCount: 120,
    summary:
        'One of the last surahs revealed. Named after the table spread with food that the disciples of Jesus requested. Emphasizes fulfilling covenants and completing the message of Islam.',
    keyThemes: [
      'Fulfilling covenants',
      'Dietary laws',
      'Completion of religion',
      'Justice',
    ],
  ),
  6: SurahIntroData(
    id: 6,
    nameArabic: 'الأنعام',
    nameEnglish: 'Al-An\'am',
    meaningOfName: 'The Cattle',
    revelationType: 'Meccan',
    versesCount: 165,
    summary:
        'A powerful Meccan surah revealed entirely at once. Establishes monotheism, refutes polytheism, and presents arguments for the existence and oneness of God through signs in nature.',
    keyThemes: [
      'Monotheism',
      'Signs in creation',
      'Refuting polytheism',
      'Prophethood',
    ],
  ),
  7: SurahIntroData(
    id: 7,
    nameArabic: 'الأعراف',
    nameEnglish: 'Al-A\'raf',
    meaningOfName: 'The Heights',
    revelationType: 'Meccan',
    versesCount: 206,
    summary:
        'Chronicles the stories of earlier prophets — Adam, Noah, Hud, Salih, Lot, Shu\'ayb, and Moses. Named after the elevated barrier between Paradise and Hell on the Day of Judgment.',
    keyThemes: [
      'Prophet stories',
      'Consequences of rejection',
      'The Day of Judgment',
      'Adam\'s story',
    ],
  ),
  8: SurahIntroData(
    id: 8,
    nameArabic: 'الأنفال',
    nameEnglish: 'Al-Anfal',
    meaningOfName: 'The Spoils of War',
    revelationType: 'Medinan',
    versesCount: 75,
    summary:
        'Revealed after the Battle of Badr, the first major military victory of Islam. Addresses the distribution of war spoils, the ethics of warfare, and lessons from the battle.',
    keyThemes: [
      'Battle of Badr',
      'War ethics',
      'Trust in Allah',
      'Unity of believers',
    ],
  ),
  9: SurahIntroData(
    id: 9,
    nameArabic: 'التوبة',
    nameEnglish: 'At-Tawbah',
    meaningOfName: 'The Repentance',
    revelationType: 'Medinan',
    versesCount: 129,
    summary:
        'The only surah without Bismillah. Deals with the treaties with polytheists, the hypocrites in Medina, and the Tabuk expedition. Emphasizes sincere repentance.',
    keyThemes: [
      'Repentance',
      'Hypocrites',
      'Tabuk expedition',
      'Breaking of treaties',
    ],
  ),
  10: SurahIntroData(
    id: 10,
    nameArabic: 'يونس',
    nameEnglish: 'Yunus',
    meaningOfName: 'Jonah',
    revelationType: 'Meccan',
    versesCount: 109,
    summary:
        'Named after Prophet Yunus (Jonah) whose people uniquely repented and were saved. Discusses the nature of revelation, free will, and the consequences of accepting or rejecting truth.',
    keyThemes: [
      'Revelation',
      'Prophet Yunus',
      'Free will',
      'Mercy of repentance',
    ],
  ),
  11: SurahIntroData(
    id: 11,
    nameArabic: 'هود',
    nameEnglish: 'Hud',
    meaningOfName: 'Hud',
    revelationType: 'Meccan',
    versesCount: 123,
    summary:
        'Named after Prophet Hud, sent to the people of \'Ad. Presents a series of prophet stories as warnings, culminating in the story of Noah\'s flood with vivid dramatic detail.',
    keyThemes: [
      'Prophet stories',
      'Noah\'s flood',
      'Patience in adversity',
      'Divine justice',
    ],
  ),
  12: SurahIntroData(
    id: 12,
    nameArabic: 'يوسف',
    nameEnglish: 'Yusuf',
    meaningOfName: 'Joseph',
    revelationType: 'Meccan',
    versesCount: 111,
    summary:
        'The most cohesive narrative in the Quran, telling the complete story of Prophet Yusuf — from his dream as a child to his reunion with his family as a minister of Egypt. Called "the best of stories."',
    keyThemes: [
      'Patience and trust',
      'Dreams and interpretation',
      'Temptation and chastity',
      'Family reconciliation',
    ],
  ),
  13: SurahIntroData(
    id: 13,
    nameArabic: 'الرعد',
    nameEnglish: 'Ar-Ra\'d',
    meaningOfName: 'The Thunder',
    revelationType: 'Medinan',
    versesCount: 43,
    summary:
        'Named after the thunder that glorifies Allah. Presents powerful signs in nature as evidence of God\'s existence and the truth of revelation.',
    keyThemes: [
      'Signs in nature',
      'Monotheism',
      'Guidance vs. misguidance',
    ],
  ),
  14: SurahIntroData(
    id: 14,
    nameArabic: 'إبراهيم',
    nameEnglish: 'Ibrahim',
    meaningOfName: 'Abraham',
    revelationType: 'Meccan',
    versesCount: 52,
    summary:
        'Named after Prophet Ibrahim and his prayer when settling his family in Mecca. Contrasts gratitude with ingratitude and light with darkness.',
    keyThemes: [
      'Ibrahim\'s prayers',
      'Gratitude',
      'Light vs. darkness',
      'Prophethood',
    ],
  ),
  15: SurahIntroData(
    id: 15,
    nameArabic: 'الحجر',
    nameEnglish: 'Al-Hijr',
    meaningOfName: 'The Rocky Tract',
    revelationType: 'Meccan',
    versesCount: 99,
    summary:
        'Named after the rocky region where the people of Thamud lived. Discusses the creation of humans and jinn, the story of Iblis, and the destruction of past nations.',
    keyThemes: [
      'Creation of Adam',
      'Story of Iblis',
      'Destroyed nations',
      'Protection of the Quran',
    ],
  ),
  16: SurahIntroData(
    id: 16,
    nameArabic: 'النحل',
    nameEnglish: 'An-Nahl',
    meaningOfName: 'The Bee',
    revelationType: 'Meccan',
    versesCount: 128,
    summary:
        'Named after the bee, presented as a sign of Allah\'s creative wisdom. Catalogues blessings and signs in nature — from rain and crops to animals and the sea.',
    keyThemes: [
      'Blessings of Allah',
      'Signs in nature',
      'The bee',
      'Gratitude',
    ],
  ),
  17: SurahIntroData(
    id: 17,
    nameArabic: 'الإسراء',
    nameEnglish: 'Al-Isra',
    meaningOfName: 'The Night Journey',
    revelationType: 'Meccan',
    versesCount: 111,
    summary:
        'Opens with the miraculous Night Journey (Isra) from Mecca to Jerusalem. Contains a "mini-code of conduct" with ethical commandments, and discusses the Israelites\' history.',
    keyThemes: [
      'Night Journey',
      'Ethical commandments',
      'Children of Israel',
      'The Quran\'s miracle',
    ],
  ),
  18: SurahIntroData(
    id: 18,
    nameArabic: 'الكهف',
    nameEnglish: 'Al-Kahf',
    meaningOfName: 'The Cave',
    revelationType: 'Meccan',
    versesCount: 110,
    summary:
        'Contains four powerful parables: the Sleepers of the Cave, the owner of two gardens, Musa and Khidr, and Dhul-Qarnayn. Recommended to recite every Friday.',
    keyThemes: [
      'Trial of faith',
      'Trial of wealth',
      'Trial of knowledge',
      'Trial of power',
    ],
  ),
  19: SurahIntroData(
    id: 19,
    nameArabic: 'مريم',
    nameEnglish: 'Maryam',
    meaningOfName: 'Mary',
    revelationType: 'Meccan',
    versesCount: 98,
    summary:
        'Named after Maryam (Mary), the mother of Jesus. Tells the stories of Zakariya, Yahya (John the Baptist), Maryam, and Jesus — emphasizing the miraculous nature of their births.',
    keyThemes: [
      'Maryam and Jesus',
      'Mercy and miracles',
      'Ibrahim and his father',
      'Prophets\' lineage',
    ],
  ),
  20: SurahIntroData(
    id: 20,
    nameArabic: 'طه',
    nameEnglish: 'Ta-Ha',
    meaningOfName: 'Ta-Ha',
    revelationType: 'Meccan',
    versesCount: 135,
    summary:
        'Opens with mysterious letters. Contains the most detailed account of Prophet Musa\'s story — from his call at the burning bush to the confrontation with Pharaoh and Samiri.',
    keyThemes: [
      'Story of Musa',
      'Pharaoh',
      'The burning bush',
      'Adam in Paradise',
    ],
  ),
  36: SurahIntroData(
    id: 36,
    nameArabic: 'يس',
    nameEnglish: 'Ya-Sin',
    meaningOfName: 'Ya-Sin',
    revelationType: 'Meccan',
    versesCount: 83,
    summary:
        'Called "the Heart of the Quran." Addresses the fundamental themes of monotheism, prophethood, and resurrection through powerful parables and signs in nature.',
    keyThemes: [
      'Resurrection',
      'Signs in creation',
      'Parable of the messengers',
      'Heart of the Quran',
    ],
  ),
  55: SurahIntroData(
    id: 55,
    nameArabic: 'الرحمن',
    nameEnglish: 'Ar-Rahman',
    meaningOfName: 'The Most Merciful',
    revelationType: 'Medinan',
    versesCount: 78,
    summary:
        'The Surah of Beauty. Enumerates the blessings of Allah with the recurring refrain "Which of the favors of your Lord will you deny?" — addressed to both humans and jinn.',
    keyThemes: [
      'Blessings of Allah',
      'The refrain',
      'Paradise described',
      'Balance in creation',
    ],
  ),
  67: SurahIntroData(
    id: 67,
    nameArabic: 'الملك',
    nameEnglish: 'Al-Mulk',
    meaningOfName: 'The Sovereignty',
    revelationType: 'Meccan',
    versesCount: 30,
    summary:
        'Also called "The Protector." The Prophet ﷺ recommended reading it every night. Discusses Allah\'s power in creating the heavens and earth, and the fate of disbelievers.',
    keyThemes: [
      'Allah\'s sovereignty',
      'Creation of the heavens',
      'Protection from punishment',
    ],
  ),
  112: SurahIntroData(
    id: 112,
    nameArabic: 'الإخلاص',
    nameEnglish: 'Al-Ikhlas',
    meaningOfName: 'The Sincerity',
    revelationType: 'Meccan',
    versesCount: 4,
    summary:
        'Equal to one-third of the Quran in meaning. A concise declaration of pure monotheism (tawhid) that defines God\'s nature in four verses.',
    keyThemes: ['Pure monotheism', 'Oneness of God', 'Essence of faith'],
  ),
  113: SurahIntroData(
    id: 113,
    nameArabic: 'الفلق',
    nameEnglish: 'Al-Falaq',
    meaningOfName: 'The Daybreak',
    revelationType: 'Meccan',
    versesCount: 5,
    summary:
        'One of the two protective surahs (al-Mu\'awwidhatayn). Seeks refuge in Allah from external evils — darkness, magic, and envy.',
    keyThemes: ['Seeking refuge', 'Protection from evil', 'Dawn'],
  ),
  114: SurahIntroData(
    id: 114,
    nameArabic: 'الناس',
    nameEnglish: 'An-Nas',
    meaningOfName: 'Mankind',
    revelationType: 'Meccan',
    versesCount: 6,
    summary:
        'The final surah of the Quran. Seeks refuge in Allah from the whisperings of Satan — the internal spiritual threat. Paired with Al-Falaq for complete protection.',
    keyThemes: [
      'Seeking refuge',
      'Whisperings of Satan',
      'Spiritual protection',
    ],
  ),
};
