import 'package:flutter/material.dart';

/// Lightweight manual localization — no intl/arb codegen needed.
/// Usage: `AppLocalizations.of(context).t('key')`
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// Get the translated string for [key]. Falls back to English.
  String t(String key) {
    return _strings[locale.languageCode]?[key] ?? _strings['en']?[key] ?? key;
  }

  // ── All translatable strings ──
  static const Map<String, Map<String, String>> _strings = {
    'en': {
      // Bottom Nav
      'nav_home': 'Home',
      'nav_read': 'Read',
      'nav_audio': 'Audio',
      'nav_hifz': 'Hifz',
      'nav_profile': 'Profile',

      // Home Screen
      'home_greeting': 'Assalamu Alaikum',
      'home_resume_title': 'Resume Your Journey',
      'home_resume_subtitle': 'Continue where you left off',
      'home_continue': 'Continue Reading',
      'home_no_history': 'Start reading to track your progress',
      'home_quick_access': 'Quick Access',
      'home_bookmarks': 'Bookmarks',
      'home_random': 'Random\nPage',
      'home_ayah_title': 'Ayah of the Day',
      'home_ayah_subtitle': 'Daily inspiration from the Quran',
      'home_hifz_title': 'Hifz Progress',
      'home_hifz_subtitle': 'Memorization journey',
      'home_coming_soon': 'Coming Soon',
      'home_loading': 'Loading verse...',
      'home_page': 'Page',
      'home_read': 'Read',

      // Read Index
      'read_title': 'Read',
      'read_subtitle': 'Explore the Holy Quran',
      'read_search_hint': 'Search surahs...',
      'read_tab_surah': 'Surah',
      'read_tab_juz': 'Juz',
      'read_tab_hizb': 'Hizb',
      'read_verses': 'verses',
      'read_pages': 'Pages',

      // Audio Screen
      'audio_title': 'Listen',
      'audio_subtitle': 'Explore reciters and listen to the Quran',
      'audio_search_hint': 'Search reciters or surahs...',
      'audio_tab_reciters': 'Reciters',
      'audio_tab_surahs': 'Surahs',
      'audio_now_playing': 'Now Playing',
      'audio_active': 'Active',
      'audio_verses': 'verses',

      // Hifz Screen
      'hifz_title': 'Memorization',
      'hifz_subtitle': 'Track your Hifz journey',
      'hifz_day_streak': 'Day streak',
      'hifz_best_streak': 'Best streak',
      'hifz_sabaq': 'Sabaq',
      'hifz_sabaq_desc': 'New lessons',
      'hifz_sabqi': 'Sabqi',
      'hifz_sabqi_desc': 'Recent review',
      'hifz_manzil': 'Manzil',
      'hifz_manzil_desc': 'Mastered',
      'hifz_overall': 'Overall Progress',
      'hifz_of_surahs': 'of 114 surahs',
      'hifz_all_surahs': 'All Surahs',
      'hifz_not_started': 'Not Started',
      'hifz_learning': 'Learning (Sabaq)',
      'hifz_reviewing': 'Reviewing (Sabqi)',
      'hifz_memorized': 'Memorized (Manzil)',
      'hifz_mark_reviewed': 'Mark Reviewed Today',
      'hifz_total': 'total',
      'hifz_never_reviewed': 'Never reviewed',
      'hifz_last_reviewed': 'Last reviewed:',

      // Profile Screen
      'profile_title': 'Settings',
      'profile_subtitle': 'Customize your experience',
      'profile_journey': 'Your Journey',
      'profile_memorized': 'Memorized',
      'profile_last_page': 'Last page',
      'profile_appearance': 'Appearance',
      'profile_language': 'Language',
      'profile_theme_classic': 'Classic',
      'profile_theme_warm': 'Warm',
      'profile_theme_dark': 'Dark',
      'profile_bookmarks_title': 'Your Bookmarks',
      'profile_bookmarks_desc': 'Save and organize your favorite verses',
      'profile_soon': 'Soon',
      'profile_about': 'About',
      'profile_version': 'Version 1.0.0',
      'profile_made_with': 'Made with love',
      'profile_companion': 'A modern Quran companion',
      'profile_data': 'Data Source',

      // Sheets
      'sheet_go_to_page': 'Go to page',
      'sheet_search_hint': 'Search...',
      'sheet_search_reciters': 'Search reciters...',
      'sheet_tab_all': 'All',
      'sheet_tab_recent': 'Recent',
      'sheet_tab_favorites': 'Favorites',

      // General
      'loading': 'Loading...',
    },

    'ar': {
      // Bottom Nav
      'nav_home': 'الرئيسية',
      'nav_read': 'القراءة',
      'nav_audio': 'الاستماع',
      'nav_hifz': 'الحفظ',
      'nav_profile': 'الإعدادات',

      // Home Screen
      'home_greeting': 'السلام عليكم',
      'home_resume_title': 'أكمل رحلتك',
      'home_resume_subtitle': 'تابع من حيث توقفت',
      'home_continue': 'أكمل القراءة',
      'home_no_history': 'ابدأ القراءة لتتبع تقدمك',
      'home_quick_access': 'وصول سريع',
      'home_bookmarks': 'العلامات',
      'home_random': 'صفحة\nعشوائية',
      'home_ayah_title': 'آية اليوم',
      'home_ayah_subtitle': 'إلهام يومي من القرآن الكريم',
      'home_hifz_title': 'تقدم الحفظ',
      'home_hifz_subtitle': 'رحلة الحفظ',
      'home_coming_soon': 'قريباً',
      'home_loading': 'جاري تحميل الآية...',
      'home_page': 'صفحة',
      'home_read': 'القراءة',

      // Read Index
      'read_title': 'القراءة',
      'read_subtitle': 'تصفح القرآن الكريم',
      'read_search_hint': 'ابحث عن سورة...',
      'read_tab_surah': 'سورة',
      'read_tab_juz': 'جزء',
      'read_tab_hizb': 'حزب',
      'read_verses': 'آيات',
      'read_pages': 'صفحات',

      // Audio Screen
      'audio_title': 'الاستماع',
      'audio_subtitle': 'استكشف القراء واستمع للقرآن',
      'audio_search_hint': 'ابحث عن قارئ أو سورة...',
      'audio_tab_reciters': 'القراء',
      'audio_tab_surahs': 'السور',
      'audio_now_playing': 'يعمل الآن',
      'audio_active': 'نشط',
      'audio_verses': 'آيات',

      // Hifz Screen
      'hifz_title': 'الحفظ',
      'hifz_subtitle': 'تتبع رحلة حفظك',
      'hifz_day_streak': 'أيام متتالية',
      'hifz_best_streak': 'أفضل سلسلة',
      'hifz_sabaq': 'سبق',
      'hifz_sabaq_desc': 'دروس جديدة',
      'hifz_sabqi': 'سبقي',
      'hifz_sabqi_desc': 'مراجعة حديثة',
      'hifz_manzil': 'منزل',
      'hifz_manzil_desc': 'متقن',
      'hifz_overall': 'التقدم العام',
      'hifz_of_surahs': 'من 114 سورة',
      'hifz_all_surahs': 'جميع السور',
      'hifz_not_started': 'لم يبدأ',
      'hifz_learning': 'قيد التعلم (سبق)',
      'hifz_reviewing': 'قيد المراجعة (سبقي)',
      'hifz_memorized': 'محفوظ (منزل)',
      'hifz_mark_reviewed': 'تمت المراجعة اليوم',
      'hifz_total': 'إجمالي',
      'hifz_never_reviewed': 'لم تتم مراجعته',
      'hifz_last_reviewed': 'آخر مراجعة:',

      // Profile Screen
      'profile_title': 'الإعدادات',
      'profile_subtitle': 'خصص تجربتك',
      'profile_journey': 'رحلتك',
      'profile_memorized': 'محفوظ',
      'profile_last_page': 'آخر صفحة',
      'profile_appearance': 'المظهر',
      'profile_language': 'اللغة',
      'profile_theme_classic': 'كلاسيكي',
      'profile_theme_warm': 'دافئ',
      'profile_theme_dark': 'داكن',
      'profile_bookmarks_title': 'علاماتك المرجعية',
      'profile_bookmarks_desc': 'احفظ ونظم آياتك المفضلة',
      'profile_soon': 'قريباً',
      'profile_about': 'حول',
      'profile_version': 'الإصدار 1.0.0',
      'profile_made_with': 'صُنع بحب',
      'profile_companion': 'رفيق قرآني عصري',
      'profile_data': 'مصدر البيانات',

      // Sheets
      'sheet_go_to_page': 'انتقل إلى صفحة',
      'sheet_search_hint': 'بحث...',
      'sheet_search_reciters': 'ابحث عن قارئ...',
      'sheet_tab_all': 'الكل',
      'sheet_tab_recent': 'الأخيرة',
      'sheet_tab_favorites': 'المفضلة',

      // General
      'loading': 'جاري التحميل...',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
