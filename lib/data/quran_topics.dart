// Curated Quranic themes and stories for the Understand tab.
//
// Static data mapped to surah IDs for cross-referencing with the surah browser.
// Each topic links to the surahs where it prominently appears.

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// A thematic topic or story arc in the Quran.
class QuranTopic {
  final String id;
  final String title;
  final String titleAr;
  final String subtitle;
  final String subtitleAr;
  final IconData icon;
  final List<int> surahIds; // Primary surahs where this topic features
  final Color color;

  const QuranTopic({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.subtitle,
    required this.subtitleAr,
    required this.icon,
    required this.surahIds,
    required this.color,
  });
}

// ── Prophet Stories ──

const List<QuranTopic> prophetStories = [
  QuranTopic(
    id: 'musa',
    title: 'Musa & Pharaoh',
    titleAr: 'موسى وفرعون',
    subtitle: 'The most told story in the Quran',
    subtitleAr: 'القصة الأكثر ذكراً في القرآن',
    icon: LucideIcons.flame,
    surahIds: [2, 7, 10, 20, 26, 28, 40, 79],
    color: Color(0xFFE57373),
  ),
  QuranTopic(
    id: 'yusuf',
    title: 'Yusuf',
    titleAr: 'يوسف',
    subtitle: '"The best of stories"',
    subtitleAr: '"أحسن القصص"',
    icon: LucideIcons.star,
    surahIds: [12],
    color: Color(0xFF81C784),
  ),
  QuranTopic(
    id: 'ibrahim',
    title: 'Ibrahim',
    titleAr: 'إبراهيم',
    subtitle: 'The father of prophets',
    subtitleAr: 'أبو الأنبياء',
    icon: LucideIcons.mountain,
    surahIds: [2, 6, 14, 15, 19, 21, 37],
    color: Color(0xFF64B5F6),
  ),
  QuranTopic(
    id: 'nuh',
    title: 'Nuh & the Flood',
    titleAr: 'نوح والطوفان',
    subtitle: '950 years of patience',
    subtitleAr: '950 عاماً من الصبر',
    icon: LucideIcons.waves,
    surahIds: [7, 11, 23, 26, 54, 71],
    color: Color(0xFF4FC3F7),
  ),
  QuranTopic(
    id: 'isa_maryam',
    title: 'Isa & Maryam',
    titleAr: 'عيسى ومريم',
    subtitle: 'The miraculous birth',
    subtitleAr: 'الولادة المعجزة',
    icon: LucideIcons.sparkles,
    surahIds: [3, 5, 19, 61],
    color: Color(0xFFBA68C8),
  ),
  QuranTopic(
    id: 'adam',
    title: 'Adam & Iblis',
    titleAr: 'آدم وإبليس',
    subtitle: 'The origin story',
    subtitleAr: 'قصة البداية',
    icon: LucideIcons.trees,
    surahIds: [2, 7, 15, 17, 20, 38],
    color: Color(0xFF66BB6A),
  ),
  QuranTopic(
    id: 'dawud_sulayman',
    title: 'Dawud & Sulayman',
    titleAr: 'داود وسليمان',
    subtitle: 'Kings and prophets',
    subtitleAr: 'ملوك وأنبياء',
    icon: LucideIcons.crown,
    surahIds: [21, 27, 34, 38],
    color: Color(0xFFFFB74D),
  ),
  QuranTopic(
    id: 'dhul_qarnayn',
    title: 'Dhul-Qarnayn',
    titleAr: 'ذو القرنين',
    subtitle: 'The great traveller',
    subtitleAr: 'الرحالة العظيم',
    icon: LucideIcons.compass,
    surahIds: [18],
    color: Color(0xFF4DD0E1),
  ),
  QuranTopic(
    id: 'khidr',
    title: 'Musa & Khidr',
    titleAr: 'موسى والخضر',
    subtitle: 'Hidden wisdom',
    subtitleAr: 'الحكمة الخفية',
    icon: LucideIcons.eyeOff,
    surahIds: [18],
    color: Color(0xFF9575CD),
  ),
  QuranTopic(
    id: 'luqman',
    title: 'Luqman the Wise',
    titleAr: 'لقمان الحكيم',
    subtitle: "A father's advice",
    subtitleAr: 'نصيحة أب',
    icon: LucideIcons.messageCircle,
    surahIds: [31],
    color: Color(0xFF7986CB),
  ),
];

// ── Quranic Themes ──

const List<QuranTopic> quranThemes = [
  QuranTopic(
    id: 'tawhid',
    title: 'Monotheism',
    titleAr: 'التوحيد',
    subtitle: 'The oneness of God',
    subtitleAr: 'وحدانية الله',
    icon: LucideIcons.circle,
    surahIds: [1, 2, 6, 112],
    color: Color(0xFF42A5F5),
  ),
  QuranTopic(
    id: 'akhirah',
    title: 'The Afterlife',
    titleAr: 'الآخرة',
    subtitle: 'Paradise, Hell & Judgment',
    subtitleAr: 'الجنة والنار والحساب',
    icon: LucideIcons.sunrise,
    surahIds: [36, 50, 56, 69, 75, 78, 81, 82, 84, 99, 101],
    color: Color(0xFFFF7043),
  ),
  QuranTopic(
    id: 'patience',
    title: 'Patience & Trust',
    titleAr: 'الصبر والتوكل',
    subtitle: 'Enduring with faith',
    subtitleAr: 'التحمل بإيمان',
    icon: LucideIcons.anchor,
    surahIds: [2, 3, 12, 18, 93, 94],
    color: Color(0xFF26A69A),
  ),
  QuranTopic(
    id: 'justice',
    title: 'Justice & Equity',
    titleAr: 'العدل والمساواة',
    subtitle: 'Social and divine justice',
    subtitleAr: 'العدالة الاجتماعية والإلهية',
    icon: LucideIcons.scale,
    surahIds: [4, 5, 16, 42, 49, 83],
    color: Color(0xFF5C6BC0),
  ),
  QuranTopic(
    id: 'nature',
    title: 'Signs in Nature',
    titleAr: 'آيات في الطبيعة',
    subtitle: 'Creation as evidence',
    subtitleAr: 'الخلق كدليل',
    icon: LucideIcons.leaf,
    surahIds: [6, 13, 16, 30, 36, 55],
    color: Color(0xFF66BB6A),
  ),
  QuranTopic(
    id: 'mercy',
    title: 'Mercy & Forgiveness',
    titleAr: 'الرحمة والمغفرة',
    subtitle: 'The door is always open',
    subtitleAr: 'الباب مفتوح دائماً',
    icon: LucideIcons.heart,
    surahIds: [9, 39, 55, 93],
    color: Color(0xFFEF5350),
  ),
  QuranTopic(
    id: 'gratitude',
    title: 'Gratitude',
    titleAr: 'الشكر',
    subtitle: 'Counting blessings',
    subtitleAr: 'إحصاء النعم',
    icon: LucideIcons.gift,
    surahIds: [14, 16, 31, 55],
    color: Color(0xFFFFA726),
  ),
  QuranTopic(
    id: 'parables',
    title: 'Parables',
    titleAr: 'الأمثال',
    subtitle: 'Lessons through stories',
    subtitleAr: 'دروس عبر القصص',
    icon: LucideIcons.lightbulb,
    surahIds: [2, 13, 14, 16, 18, 24, 29, 59],
    color: Color(0xFFFFCA28),
  ),
  QuranTopic(
    id: 'family',
    title: 'Family & Society',
    titleAr: 'الأسرة والمجتمع',
    subtitle: 'Rights and responsibilities',
    subtitleAr: 'الحقوق والواجبات',
    icon: LucideIcons.users,
    surahIds: [2, 4, 24, 33, 49, 65, 66],
    color: Color(0xFF78909C),
  ),
  QuranTopic(
    id: 'dua',
    title: "Du'a & Worship",
    titleAr: 'الدعاء والعبادة',
    subtitle: 'Conversations with God',
    subtitleAr: 'مناجاة الله',
    icon: LucideIcons.hand,
    surahIds: [1, 2, 3, 14, 25, 40],
    color: Color(0xFF8D6E63),
  ),
];
