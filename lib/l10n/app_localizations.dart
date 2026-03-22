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
      'nav_dashboard': 'Dashboard',
      'nav_practice': 'Practice',
      'nav_read': 'Read',
      'nav_listen': 'Listen',
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
      'home_welcome': 'Welcome',
      'home_just_now': 'Just now',
      'home_min_ago': 'm ago',
      'home_hour_ago': 'h ago',
      'home_yesterday': 'Yesterday',
      'home_days_ago': 'days ago',

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
      'profile_reading': 'Reading',
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
      'profile_replay_onboarding': 'Replay Onboarding',
      'profile_replay_onboarding_desc':
          'Change language and reading preference',

      // Reading Screen Chrome
      'reading_read': 'Read',
      'reading_tafsir': 'Tafsir',
      'reading_select_verse': 'Select a verse',

      // Theme Picker Sheet
      'theme_appearance': 'Appearance',
      'theme_classic': 'Classic',
      'theme_warm': 'Warm',
      'theme_dark': 'Dark',
      'theme_active': 'Active',
      'theme_fit_screen': 'Fit Screen Height',
      'theme_fit_screen_desc':
          'Auto-calculates the perfect font size to fit the entire page without scrolling.',
      'theme_font_size': 'Font Size',
      'theme_line_spacing': 'Line Spacing',
      'theme_text_align': 'Text Align',
      'theme_content_align': 'Content Align',
      'theme_overlay_typo': 'Overlay Typography',
      'theme_opacity': 'Opacity',
      'theme_overlay_indicators': 'Overlay Indicators',
      'theme_alternate_info': 'Alternate Info Layout per Page',
      'theme_show_hizb': 'Show Hizb Info',
      'theme_show_juz': 'Show Juz Info',
      'theme_show_book_icon': 'Show Book Icon Indicator',
      'theme_page_shadow': 'Page Shadow Effects',
      'theme_center_spine': 'Center Spine',
      'theme_outer_edge': 'Outer Edge',
      'theme_intensity': 'Intensity',
      'theme_spine_width': 'Spine Width',
      'theme_edge_width': 'Edge Width',
      'theme_spine_padding': 'Spine Padding',
      'theme_edge_padding': 'Edge Padding',


      // Daily Werd
      'werd_set_title': 'Set Your Daily Werd',
      'werd_set_desc':
          'Create a daily recitation goal to\nstay consistent with your reading',
      'werd_get_started': 'Get Started',
      'werd_daily': 'Daily Werd',
      'werd_complete': 'Masha\'Allah! 🎉',
      'werd_complete_desc': 'You completed your daily werd',
      'werd_pages_of': 'of',
      'werd_pages_label': 'pages',
      'werd_pages_remaining': 'pages remaining today',
      'werd_pages_range': 'Pages',
      'werd_start_reading': 'Start Reading',
      'werd_setup_title': 'Daily Werd Setup',
      'werd_setup_desc': 'Set your daily Quran reading goal',
      'werd_fixed_range': 'Fixed Range',
      'werd_daily_pages': 'Daily Pages',
      'werd_from_page': 'From Page',
      'werd_to_page': 'To Page',
      'werd_pages_per_day': 'Pages per day',
      'werd_1_page': '1 page',
      'werd_30_pages': '30 pages',
      'werd_save': 'Save Werd',
      'werd_summary_fixed': 'Read {pages} pages daily (Pages {start}–{end})',
      'werd_summary_daily': 'Read {pages} pages daily ≈ {days} days to finish',
      'werd_error_range': 'Start page must be before end page',

      // Nav Menu Sheet
      'nav_index': 'Index',
      'nav_tab_surah': 'Surah',
      'nav_tab_juz': 'Juz',
      'nav_tab_bookmarks': 'Bookmarks',
      'nav_search_hint': 'Search surah name or number...',
      'nav_juz_coming': 'Juz list coming soon',
      'nav_ayahs': 'Ayahs',
      'nav_no_bookmarks': 'No bookmarks yet',
      'nav_bookmark_hint': 'Tap the bookmark icon on any surah',
      'nav_page': 'Page',
      'nav_pages': 'Pages',
      'nav_verses': 'Verses',
      'nav_no_page_bookmarks': 'No page bookmarks yet',
      'nav_page_bookmark_hint': 'Tap the bookmark icon in the top bar\nwhile reading to save a page',
      'nav_no_verse_bookmarks': 'No verse bookmarks yet',
      'nav_verse_bookmark_hint': 'Long-press any verse and tap the\nbookmark icon to save it',

      // Bookmark Edit & Collections
      'bm_edit_title': 'Edit Bookmark',
      'bm_color': 'Color',
      'bm_note': 'Note',
      'bm_note_hint': 'Add a personal note...',
      'bm_collection': 'Collection',
      'bm_uncategorized': 'Uncategorized',
      'bm_delete': 'Delete Bookmark',
      'bm_all': 'All',
      'bm_new_collection': 'New Collection',
      'bm_collection_name_hint': 'e.g. Favorite Duas',
      'bm_cancel': 'Cancel',
      'bm_create': 'Create',
      'bm_add': 'Add',
      'bm_rename': 'Rename',
      'bm_delete_collection': 'Delete Collection',
      'bm_save': 'Save',

      // Reciter Menu Sheet
      'reciter_title': 'Select Reciter',
      'reciter_search_hint': 'Search by reciter name...',
      'reciter_tab_favorites': 'Favorites',
      'reciter_tab_recent': 'Recent',
      'reciter_tab_all': 'All',
      'reciter_hafs': 'Hafs',
      'reciter_warsh': 'Warsh',
      'reciter_style_all': 'All',
      'reciter_recitation': 'Recitation',
      'reciter_standard': 'Standard',
      'reciter_no_favorites': 'No favorite reciters yet',
      'reciter_no_recent': 'No recent reciters',
      'reciter_no_found': 'No reciters found',

      // Search Sheet
      'search_title': 'Search',
      'search_hint': 'Search surah name or number...',
      'search_no_results': 'No results found',

      // Audio Settings Sheet
      'audio_settings_title': 'Audio Settings',
      'audio_playback_speed': 'Playback Speed',
      'audio_repeat_mode': 'Repeat Mode',
      'audio_repeat_off': 'Off',
      'audio_repeat_verse': 'Verse',
      'audio_repeat_times': 'Repeat times',

      // Reading Edge Info
      'reading_juz': 'Juz',
      'reading_hizb': 'Hizb',
      'reading_verse': 'Verse',
      'reading_playing': 'Playing...',
      'reading_page_na': 'Page not available',

      // Practice Screen
      'practice_title': 'Practice',
      'practice_subtitle': 'Strengthen your memorization',
      'practice_coming_title': 'Coming Soon',
      'practice_coming_desc': 'Flashcards and mutashabihat drills to reinforce your memorization journey.',
      'practice_flashcards': 'Flashcards',
      'practice_mutashabihat': 'Mutashabihat',

      // General
      'loading': 'Loading...',

      // In-App Update
      'update_available': 'Update Available',
      'update_whats_new': 'What\'s New',
      'update_now': 'Update Now',
      'update_later': 'Later',
      'update_downloading': 'Downloading...',
      'update_error': 'Update failed. Please try again later.',
    },

    'ar': {
      // Bottom Nav
      'nav_home': 'الرئيسية',
      'nav_dashboard': 'الرئيسية',
      'nav_practice': 'التدريب',
      'nav_read': 'القراءة',
      'nav_listen': 'الاستماع',
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
      'home_welcome': 'أهلاً وسهلاً',
      'home_just_now': 'الآن',
      'home_min_ago': 'د مضت',
      'home_hour_ago': 'س مضت',
      'home_yesterday': 'أمس',
      'home_days_ago': 'أيام مضت',

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
      'profile_reading': 'القراءة',
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
      'profile_replay_onboarding': 'إعادة الإعداد الأولي',
      'profile_replay_onboarding_desc': 'تغيير اللغة والقراءة المفضلة',

      // Reading Screen Chrome
      'reading_read': 'القراءة',
      'reading_tafsir': 'التفسير',
      'reading_select_verse': 'اختر آية',

      // Theme Picker Sheet
      'theme_appearance': 'المظهر',
      'theme_classic': 'كلاسيكي',
      'theme_warm': 'دافئ',
      'theme_dark': 'داكن',
      'theme_active': 'نشط',
      'theme_fit_screen': 'ملائمة ارتفاع الشاشة',
      'theme_fit_screen_desc':
          'يحسب حجم الخط تلقائياً ليناسب الصفحة كاملة بدون تمرير.',
      'theme_font_size': 'حجم الخط',
      'theme_line_spacing': 'تباعد الأسطر',
      'theme_text_align': 'محاذاة النص',
      'theme_content_align': 'محاذاة المحتوى',
      'theme_overlay_typo': 'خط العرض',
      'theme_opacity': 'الشفافية',
      'theme_overlay_indicators': 'مؤشرات العرض',
      'theme_alternate_info': 'تبديل تخطيط المعلومات لكل صفحة',
      'theme_show_hizb': 'إظهار معلومات الحزب',
      'theme_show_juz': 'إظهار معلومات الجزء',
      'theme_show_book_icon': 'إظهار أيقونة الكتاب',
      'theme_page_shadow': 'تأثيرات ظل الصفحة',
      'theme_center_spine': 'عمود مركزي',
      'theme_outer_edge': 'حافة خارجية',
      'theme_intensity': 'الشدة',
      'theme_spine_width': 'عرض العمود',
      'theme_edge_width': 'عرض الحافة',
      'theme_spine_padding': 'حشو العمود',
      'theme_edge_padding': 'حشو الحافة',


      // Daily Werd
      'werd_set_title': 'حدد وردك اليومي',
      'werd_set_desc':
          'أنشئ هدفاً يومياً للتلاوة\nللمحافظة على استمرارية قراءتك',
      'werd_get_started': 'ابدأ الآن',
      'werd_daily': 'الورد اليومي',
      'werd_complete': 'ماشاء الله! 🎉',
      'werd_complete_desc': 'أكملت وردك اليومي',
      'werd_pages_of': 'من',
      'werd_pages_label': 'صفحات',
      'werd_pages_remaining': 'صفحات متبقية اليوم',
      'werd_pages_range': 'صفحات',
      'werd_start_reading': 'ابدأ القراءة',
      'werd_setup_title': 'إعداد الورد اليومي',
      'werd_setup_desc': 'حدد هدفك اليومي لقراءة القرآن',
      'werd_fixed_range': 'نطاق محدد',
      'werd_daily_pages': 'صفحات يومية',
      'werd_from_page': 'من صفحة',
      'werd_to_page': 'إلى صفحة',
      'werd_pages_per_day': 'صفحات في اليوم',
      'werd_1_page': 'صفحة واحدة',
      'werd_30_pages': '30 صفحة',
      'werd_save': 'حفظ الورد',
      'werd_summary_fixed': 'اقرأ {pages} صفحات يومياً (صفحات {start}–{end})',
      'werd_summary_daily': 'اقرأ {pages} صفحات يومياً ≈ {days} أيام للإنهاء',
      'werd_error_range': 'يجب أن تكون صفحة البداية قبل صفحة النهاية',

      // Nav Menu Sheet
      'nav_index': 'الفهرس',
      'nav_tab_surah': 'سورة',
      'nav_tab_juz': 'جزء',
      'nav_tab_bookmarks': 'العلامات',
      'nav_search_hint': 'ابحث عن اسم أو رقم السورة...',
      'nav_juz_coming': 'قائمة الأجزاء قريباً',
      'nav_ayahs': 'آيات',
      'nav_no_bookmarks': 'لا توجد علامات بعد',
      'nav_bookmark_hint': 'اضغط على أيقونة العلامة في أي سورة',
      'nav_page': 'صفحة',
      'nav_pages': 'صفحات',
      'nav_verses': 'آيات',
      'nav_no_page_bookmarks': 'لا توجد علامات صفحات بعد',
      'nav_page_bookmark_hint': 'اضغط على أيقونة العلامة في الشريط العلوي\nأثناء القراءة لحفظ صفحة',
      'nav_no_verse_bookmarks': 'لا توجد علامات آيات بعد',
      'nav_verse_bookmark_hint': 'اضغط مطولاً على أي آية ثم اضغط\nعلى أيقونة العلامة لحفظها',

      // Bookmark Edit & Collections
      'bm_edit_title': 'تعديل العلامة',
      'bm_color': 'اللون',
      'bm_note': 'ملاحظة',
      'bm_note_hint': 'أضف ملاحظة شخصية...',
      'bm_collection': 'المجموعة',
      'bm_uncategorized': 'بدون تصنيف',
      'bm_delete': 'حذف العلامة',
      'bm_all': 'الكل',
      'bm_new_collection': 'مجموعة جديدة',
      'bm_collection_name_hint': 'مثال: أدعية مفضلة',
      'bm_cancel': 'إلغاء',
      'bm_create': 'إنشاء',
      'bm_add': 'إضافة',
      'bm_rename': 'إعادة تسمية',
      'bm_delete_collection': 'حذف المجموعة',
      'bm_save': 'حفظ',

      // Reciter Menu Sheet
      'reciter_title': 'اختر قارئاً',
      'reciter_search_hint': 'ابحث باسم القارئ...',
      'reciter_tab_favorites': 'المفضلة',
      'reciter_tab_recent': 'الأخيرة',
      'reciter_tab_all': 'الكل',
      'reciter_hafs': 'حفص',
      'reciter_warsh': 'ورش',
      'reciter_style_all': 'الكل',
      'reciter_recitation': 'تلاوة',
      'reciter_standard': 'عادي',
      'reciter_no_favorites': 'لا يوجد قراء مفضلون بعد',
      'reciter_no_recent': 'لا يوجد قراء مؤخراً',
      'reciter_no_found': 'لم يتم العثور على قراء',

      // Search Sheet
      'search_title': 'البحث',
      'search_hint': 'ابحث عن اسم أو رقم السورة...',
      'search_no_results': 'لا توجد نتائج',

      // Audio Settings Sheet
      'audio_settings_title': 'إعدادات الصوت',
      'audio_playback_speed': 'سرعة التشغيل',
      'audio_repeat_mode': 'وضع التكرار',
      'audio_repeat_off': 'إيقاف',
      'audio_repeat_verse': 'آية',
      'audio_repeat_times': 'عدد التكرار',

      // Reading Edge Info
      'reading_juz': 'الجزء',
      'reading_hizb': 'الحزب',
      'reading_verse': 'الآية',
      'reading_playing': 'يتم التشغيل...',
      'reading_page_na': 'الصفحة غير متوفرة',

      // Practice Screen
      'practice_title': 'التدريب',
      'practice_subtitle': 'عزز حفظك',
      'practice_coming_title': 'قريباً',
      'practice_coming_desc': 'بطاقات تدريب وتمارين المتشابهات لتعزيز رحلة حفظك.',
      'practice_flashcards': 'بطاقات تدريب',
      'practice_mutashabihat': 'المتشابهات',

      // General
      'loading': 'جاري التحميل...',

      // In-App Update
      'update_available': 'تحديث متوفر',
      'update_whats_new': 'الجديد في هذا التحديث',
      'update_now': 'تحديث الآن',
      'update_later': 'لاحقاً',
      'update_downloading': 'جاري التحميل...',
      'update_error': 'فشل التحديث. يرجى المحاولة لاحقاً.',
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
