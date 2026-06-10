import 'package:quran_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/utils/id_generator.dart';
import 'package:quran_app/providers/hifz_profile_provider.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/providers/audio_provider.dart';
import 'package:quran_app/services/local_storage_service.dart';
import 'package:quran_app/models/quran_models.dart';

import 'package:quran_app/theme/icon_resolver.dart';
import 'package:quran_app/theme/geist_typography.dart';
import 'package:quran_app/widgets/geist_button.dart';
import 'package:quran_app/services/audio_proxy_server.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// 11-screen assessment wizard for creating a Hifz memory profile.
/// Collects: name/avatar â†’ age â†’ experience â†’ learning pref â†’ encoding speed â†’
/// retention â†’ schedule+time â†’ active days â†’ goal+pace â†’ reciter â†’ starting point â†’ summary.
class AssessmentScreen extends StatefulWidget {
  final bool isRetake;

  const AssessmentScreen({super.key, this.isRetake = false});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  static const _totalPages = 7;

  // â”€â”€ Collected data â”€â”€
  String _name = '';
  int _avatarIndex = 0;
  // Birthday scroll picker state
  DateTime _birthday = DateTime(2000, 1, 1);
  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;
  AgeGroup _ageGroup = AgeGroup.youngAdult;
  HifzExperience _hifzExperience = HifzExperience.fresh;
  LearningPreference _learningPref = LearningPreference.visual;
  EncodingSpeed _encodingSpeed = EncodingSpeed.moderate;
  RetentionStrength _retention = RetentionStrength.moderate;
  int _dailyMinutes = 30;
  StudyTimeOfDay _timeOfDay = StudyTimeOfDay.fajr;
  List<int> _activeDays = [0, 1, 2, 3, 4, 5, 6]; // All days active
  HifzGoal _goal = HifzGoal.fullQuran;
  List<int> _goalDetails = [];
  PacePreference _pacePreference = PacePreference.steady;
  int _startingPage = 582; // Juz 30
  int _selectedReciterId = 7; // Mishary al-Afasy (default)

  // Reciter sample audio
  final AudioPlayer _samplePlayer = AudioPlayer();
  int? _playingReciterId;

  final _nameController = TextEditingController();
  String? _existingProfileId;
  DateTime? _existingCreatedAt;

  @override
  void initState() {
    super.initState();
    // Initialize birthday scroll controllers
    _dayController = FixedExtentScrollController(
      initialItem: _birthday.day - 1,
    );
    _monthController = FixedExtentScrollController(
      initialItem: _birthday.month - 1,
    );
    _yearController = FixedExtentScrollController(
      initialItem: _birthday.year - 1940,
    );
    // Pre-populate from existing profile ONLY if retaking assessment
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isRetake) {
        final profileProvider = context.read<HifzProfileProvider>();
        if (profileProvider.hasActiveProfile) {
          final p = profileProvider.activeProfile!;
          setState(() {
            _existingProfileId = p.id;
            _existingCreatedAt = p.createdAt;
            _name = p.name;
            _nameController.text = p.name;
            _avatarIndex = p.avatarIndex;
            if (p.birthday != null) {
              _birthday = p.birthday!;
            } else {
              // Legacy: approximate birthday from stored age
              _birthday = DateTime(DateTime.now().year - p.age, 1, 1);
            }
            _ageGroup = p.ageGroup;
            _dayController.jumpToItem(_birthday.day - 1);
            _monthController.jumpToItem(_birthday.month - 1);
            _yearController.jumpToItem(_birthday.year - 1940);
            _hifzExperience = p.hifzExperience;
            _learningPref = p.learningPreference;
            _encodingSpeed = p.encodingSpeed;
            _retention = p.retentionStrength;
            _dailyMinutes = p.dailyTimeMinutes;
            _timeOfDay = p.preferredTimeOfDay;
            _activeDays = List<int>.from(p.activeDays);
            _goal = p.goal;
            _goalDetails = p.goalDetails;
            _pacePreference = p.pacePreference;
            _startingPage = p.startingPage;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    _samplePlayer.dispose();
    super.dispose();
  }

  void _nextPage() {
    // Validate current page before proceeding
    if (_currentPage == 0 && _name.trim().isEmpty) {
      return; // Don't proceed without a name
    }
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _createProfile() async {
    final profileProvider = context.read<HifzProfileProvider>();
    final now = DateTime.now();
    // Compute age from birthday for the fallback field
    int computedAge = now.year - _birthday.year;
    if (now.month < _birthday.month ||
        (now.month == _birthday.month && now.day < _birthday.day)) {
      computedAge--;
    }
    computedAge = computedAge.clamp(7, 100);
    final profile = MemoryProfile(
      id: _existingProfileId ?? IdGenerator.uuidV4(),
      name: _name.trim(),
      avatarIndex: _avatarIndex,
      createdAt: _existingCreatedAt ?? now,
      birthday: _birthday,
      age: computedAge,
      ageGroup: _ageGroup,
      encodingSpeed: _encodingSpeed,
      retentionStrength: _retention,
      learningPreference: _learningPref,
      dailyTimeMinutes: _dailyMinutes,
      preferredTimeOfDay: _timeOfDay,
      goal: _goal,
      goalDetails: _goalDetails,
      defaultReciterId: _selectedReciterId,
      defaultReciterSource: ReciterSource.quranDotCom,
      startingPage: _startingPage,
      startDate: _existingCreatedAt ?? now,
      isActive: true,
      activeDays: _activeDays,
      pacePreference: _pacePreference,
      hifzExperience: _hifzExperience,
    );
    if (_existingProfileId != null) {
      // Retake: update existing profile, keep all progress
      await profileProvider.updateProfile(profile);
    } else {
      await profileProvider.createProfile(profile);
    }

    // Sync selected reciter as default reciter in SharedPreferences and AudioProvider
    if (mounted) {
      final storage = context.read<LocalStorageService>();
      final readingProvider = context.read<QuranReadingProvider>();
      final reciterMatch = readingProvider.reciters
          .where((r) => r.id == _selectedReciterId)
          .firstOrNull;
      if (reciterMatch != null) {
        storage.saveDefaultReciter(
          id: reciterMatch.id,
          name: reciterMatch.reciterName,
          apiSource: reciterMatch.apiSource == ApiSource.mp3Quran
              ? 'mp3Quran'
              : 'quranDotCom',
          serverUrl: reciterMatch.serverUrl,
          moshafId: reciterMatch.moshafId,
        );

        final audioProvider = context.read<AudioProvider>();
        audioProvider.setReciter(
          reciterMatch.id,
          name: reciterMatch.reciterName,
          apiSource: reciterMatch.apiSource,
          serverUrl: reciterMatch.serverUrl,
          moshafId: reciterMatch.moshafId,
        );
      } else {
        // Fallback for offline/unloaded state
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        final reciterName = isArabic
            ? (Reciter.arabicNamesById[_selectedReciterId] ??
                  'قارئ $_selectedReciterId')
            : 'Reciter $_selectedReciterId';

        storage.saveDefaultReciter(
          id: _selectedReciterId,
          name: reciterName,
          apiSource: 'quranDotCom',
        );

        final audioProvider = context.read<AudioProvider>();
        audioProvider.setReciter(
          _selectedReciterId,
          name: reciterName,
          apiSource: ApiSource.quranDotCom,
        );
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            // â”€â”€ Top bar: back + progress â”€â”€
            _buildTopBar(theme),
            // â”€â”€ Page content â”€â”€
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildIdentityPage(theme), // 0 â€” name + avatar + birthday
                  _buildExperiencePage(theme), // 1 â€” hifz experience
                  _buildMemoryProfilePage(
                    theme,
                  ), // 2 â€” encoding + retention + learning pref
                  _buildSchedulePage(
                    theme,
                  ), // 3 â€” time + time-of-day + active days
                  _buildGoalPage(theme), // 4 â€” goal + pace + starting point
                  _buildReciterPage(theme), // 5 â€” reciter + sample audio
                  _buildSummaryPage(theme), // 6 â€” summary
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // TOP BAR
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget _buildTopBar(ThemeProvider theme) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              if (_currentPage > 0)
                GeistButton.icon(
                  onPressed: _prevPage,
                  icon: Icon(
                    LucideIcons.arrowLeft,
                    size: 18,
                    color: theme.primaryText,
                  ),
                  type: GeistButtonType.secondary,
                )
              else
                GeistButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(LucideIcons.x, size: 18, color: theme.primaryText),
                  type: GeistButtonType.secondary,
                ),
              const SizedBox(width: 16),
              // Progress bar
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentPage + 1) / _totalPages,
                    backgroundColor: theme.dividerColor,
                    color: theme.accentColor,
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_currentPage + 1}/$_totalPages',
                style: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.mutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // PAGE 0: IDENTITY (name + avatar + birthday)
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  void _updateBirthday() {
    final year = 1940 + _yearController.selectedItem;
    final month = 1 + _monthController.selectedItem;
    final maxDay = DateTime(year, month + 1, 0).day;
    final day = (_dayController.selectedItem + 1).clamp(1, maxDay);
    final newBirthday = DateTime(year, month, day);
    final now = DateTime.now();
    int age = now.year - newBirthday.year;
    if (now.month < newBirthday.month ||
        (now.month == newBirthday.month && now.day < newBirthday.day)) {
      age--;
    }
    setState(() {
      _birthday = newBirthday;
      _ageGroup = MemoryProfile.ageGroupFromAge(age.clamp(7, 100));
    });
  }

  Widget _buildIdentityPage(ThemeProvider theme) {
    // Compute current age for display
    final now = DateTime.now();
    int displayAge = now.year - _birthday.year;
    if (now.month < _birthday.month ||
        (now.month == _birthday.month && now.day < _birthday.day)) {
      displayAge--;
    }
    displayAge = displayAge.clamp(0, 120);

    return _pageWrapper(
      theme,
      icon: LucideIcons.sparkles,
      title: AppLocalizations.of(context)!.assessBuildProfile,
      subtitle: AppLocalizations.of(context)!.assessQuickQuestions,
      child: Column(
        children: [
          // Name input
          TextField(
            controller: _nameController,
            onChanged: (v) => setState(() => _name = v),
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 16,
              color: theme.primaryText,
            ),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.assessNameHint,
              hintStyle: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                color: theme.mutedText,
              ),
              filled: true,
              fillColor: theme.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.accentColor, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Avatar picker
          Text(
            AppLocalizations.of(context)!.assessChooseAvatar,
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: theme.secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: List.generate(IconResolver.avatarIcons.length, (i) {
                final isSelected = _avatarIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _avatarIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected ? theme.primaryText : theme.cardColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryText.withValues(alpha: 0.08),
                          blurRadius: 0,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        IconResolver.avatarIcons[i],
                        size: 22,
                        color: isSelected
                            ? theme.scaffoldBackground
                            : theme.secondaryText,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),
          // Birthday picker label
          Text(
            'Date of Birth',
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: theme.secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          // Birthday scroll wheels
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                height: 130,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryText.withValues(alpha: 0.08),
                      blurRadius: 0,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Day
                    Expanded(
                      child: _scrollWheel(
                        theme,
                        controller: _dayController,
                        itemCount: 31,
                        labelBuilder: (i) => '${i + 1}',
                        onChanged: (_) => _updateBirthday(),
                      ),
                    ),
                    Container(width: 1, color: theme.dividerColor),
                    // Month
                    Expanded(
                      child: _scrollWheel(
                        theme,
                        controller: _monthController,
                        itemCount: 12,
                        labelBuilder: (i) => _monthNames[i],
                        onChanged: (_) => _updateBirthday(),
                      ),
                    ),
                    Container(width: 1, color: theme.dividerColor),
                    // Year
                    Expanded(
                      child: _scrollWheel(
                        theme,
                        controller: _yearController,
                        itemCount: DateTime.now().year - 1940 + 1,
                        labelBuilder: (i) => '${1940 + i}',
                        onChanged: (_) => _updateBirthday(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Computed age badge
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Container(
              key: ValueKey(displayAge),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: theme.primaryText.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                'Age $displayAge Â· ${_ageGroup.name}',
                style: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryText,
                ),
              ),
            ),
          ),
        ],
      ),
      canProceed: _name.trim().isNotEmpty,
    );
  }

  /// Reusable scroll wheel column for the birthday picker.
  Widget _scrollWheel(
    ThemeProvider theme, {
    required FixedExtentScrollController controller,
    required int itemCount,
    required String Function(int) labelBuilder,
    required ValueChanged<int> onChanged,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 36,
      physics: const FixedExtentScrollPhysics(),
      diameterRatio: 1.5,
      perspective: 0.003,
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (context, index) {
          final isSelected = controller.hasClients
              ? controller.selectedItem == index
              : false;
          return Center(
            child: Text(
              labelBuilder(index),
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: isSelected ? 18 : 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? theme.primaryText : theme.mutedText,
              ),
            ),
          );
        },
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // PAGE 3: HIFZ EXPERIENCE (NEW)
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget _buildExperiencePage(ThemeProvider theme) {
    return _pageWrapper(
      theme,
      icon: LucideIcons.compass,
      title: AppLocalizations.of(context)!.assessWhereJourney,
      subtitle: AppLocalizations.of(context)!.assessShapesPlan,
      child: Column(
        children: [
          _optionCard(
            theme,
            LucideIcons.sprout,
            AppLocalizations.of(context)!.assessFresh,
            AppLocalizations.of(context)!.assessFreshDesc,
            _hifzExperience == HifzExperience.fresh,
            () => setState(() => _hifzExperience = HifzExperience.fresh),
          ),
          const SizedBox(height: 12),
          _optionCard(
            theme,
            LucideIcons.rotateCcw,
            AppLocalizations.of(context)!.assessResuming,
            AppLocalizations.of(context)!.assessResumingDesc,
            _hifzExperience == HifzExperience.resuming,
            () => setState(() => _hifzExperience = HifzExperience.resuming),
          ),
          const SizedBox(height: 12),
          _optionCard(
            theme,
            LucideIcons.bookOpen,
            AppLocalizations.of(context)!.assessReviewing,
            AppLocalizations.of(context)!.assessReviewingDesc,
            _hifzExperience == HifzExperience.reviewing,
            () => setState(() => _hifzExperience = HifzExperience.reviewing),
          ),
        ],
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // PAGE 2: MEMORY PROFILE (encoding + retention + learning pref)
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget _buildMemoryProfilePage(ThemeProvider theme) {
    return _pageWrapper(
      theme,
      icon: LucideIcons.brain,
      title: 'Your Memory Profile',
      subtitle: 'Help us understand how you learn best',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encoding Speed
          _sectionLabel(
            theme,
            'Encoding Speed',
            'After 30 mins of practice...',
          ),
          const SizedBox(height: 8),
          _segmentedPills<EncodingSpeed>(
            theme,
            values: EncodingSpeed.values,
            selected: _encodingSpeed,
            labels: {
              EncodingSpeed.fast: 'Fast',
              EncodingSpeed.moderate: 'Moderate',
              EncodingSpeed.slow: 'Gradual',
            },
            icons: {
              EncodingSpeed.fast: LucideIcons.rocket,
              EncodingSpeed.moderate: LucideIcons.bookOpen,
              EncodingSpeed.slow: LucideIcons.gauge,
            },
            onChanged: (v) => setState(() => _encodingSpeed = v),
          ),
          const SizedBox(height: 24),
          // Retention Strength
          _sectionLabel(theme, 'Retention', 'When reciting from memory...'),
          const SizedBox(height: 8),
          _segmentedPills<RetentionStrength>(
            theme,
            values: RetentionStrength.values,
            selected: _retention,
            labels: {
              RetentionStrength.strong: 'Strong',
              RetentionStrength.moderate: 'Moderate',
              RetentionStrength.fragile: 'Fragile',
            },
            icons: {
              RetentionStrength.strong: LucideIcons.dumbbell,
              RetentionStrength.moderate: LucideIcons.helpCircle,
              RetentionStrength.fragile: LucideIcons.alertCircle,
            },
            onChanged: (v) => setState(() => _retention = v),
          ),
          const SizedBox(height: 24),
          // Learning Preference
          _sectionLabel(theme, 'Learning Style', 'What helps you memorize?'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pillChip(
                theme,
                LucideIcons.eye,
                'Visual',
                _learningPref == LearningPreference.visual,
                () => setState(() => _learningPref = LearningPreference.visual),
              ),
              _pillChip(
                theme,
                LucideIcons.ear,
                'Listening',
                _learningPref == LearningPreference.auditory,
                () =>
                    setState(() => _learningPref = LearningPreference.auditory),
              ),
              _pillChip(
                theme,
                LucideIcons.pencil,
                'Writing',
                _learningPref == LearningPreference.kinesthetic,
                () => setState(
                  () => _learningPref = LearningPreference.kinesthetic,
                ),
              ),
              _pillChip(
                theme,
                LucideIcons.repeat,
                'Repetition',
                _learningPref == LearningPreference.repetition,
                () => setState(
                  () => _learningPref = LearningPreference.repetition,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(ThemeProvider theme, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: GeistTypography.primaryFontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.primaryText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontFamily: GeistTypography.primaryFontFamily,
            fontSize: 12,
            color: theme.mutedText,
          ),
        ),
      ],
    );
  }

  Widget _segmentedPills<T>(
    ThemeProvider theme, {
    required List<T> values,
    required T selected,
    required Map<T, String> labels,
    required Map<T, IconData> icons,
    required ValueChanged<T> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: theme.primaryText.withValues(alpha: 0.08),
            blurRadius: 0,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: values.map((v) {
          final isActive = v == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(v),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? theme.primaryText : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icons[v],
                      size: 14,
                      color: isActive
                          ? theme.scaffoldBackground
                          : theme.mutedText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      labels[v]!,
                      style: TextStyle(
                        fontFamily: GeistTypography.primaryFontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? theme.scaffoldBackground
                            : theme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _pillChip(
    ThemeProvider theme,
    IconData icon,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryText : theme.cardColor,
          borderRadius: BorderRadius.circular(9999),
          boxShadow: [
            BoxShadow(
              color: theme.primaryText.withValues(alpha: 0.08),
              blurRadius: 0,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? theme.scaffoldBackground : theme.mutedText,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? theme.scaffoldBackground
                    : theme.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // PAGE 3: SCHEDULE (time + tod + active days)
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _dayIcons = IconResolver.dayIcons;

  Widget _buildSchedulePage(ThemeProvider theme) {
    return _pageWrapper(
      theme,
      icon: LucideIcons.clock,
      title: AppLocalizations.of(context)!.assessDailyCommit,
      subtitle: AppLocalizations.of(context)!.assessHowMuchTime,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time slider
          _sectionLabel(theme, 'Daily time: $_dailyMinutes minutes', ''),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: theme.primaryText,
              inactiveTrackColor: theme.dividerColor,
              thumbColor: theme.primaryText,
              overlayColor: theme.primaryText.withValues(alpha: 0.1),
              trackHeight: 4,
            ),
            child: Slider(
              value: _dailyMinutes.toDouble(),
              min: 15,
              max: 240,
              divisions: 15,
              label: '$_dailyMinutes min',
              onChanged: (v) => setState(() => _dailyMinutes = v.round()),
            ),
          ),
          const SizedBox(height: 20),
          // Time of day
          _sectionLabel(
            theme,
            AppLocalizations.of(context)!.assessPrefTime,
            '',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: StudyTimeOfDay.values.map((t) {
              final isSelected = _timeOfDay == t;
              return _pillChip(
                theme,
                _timeOfDayIcon(t),
                _timeOfDayLabel(t),
                isSelected,
                () => setState(() => _timeOfDay = t),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          // Active days
          _sectionLabel(
            theme,
            AppLocalizations.of(context)!.assessWhichDays,
            '',
          ),
          const SizedBox(height: 8),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Row(
                children: List.generate(7, (i) {
                  final isActive = _activeDays.contains(i);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isActive) {
                              if (_activeDays.length > 1) _activeDays.remove(i);
                            } else {
                              _activeDays.add(i);
                              _activeDays.sort();
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 56,
                          decoration: BoxDecoration(
                            color: isActive
                                ? theme.primaryText
                                : theme.cardColor,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: theme.primaryText.withValues(
                                  alpha: 0.08,
                                ),
                                blurRadius: 0,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _dayIcons[i],
                                size: 12,
                                color: isActive
                                    ? theme.scaffoldBackground
                                    : theme.mutedText,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _dayLabels[i],
                                style: TextStyle(
                                  fontFamily: GeistTypography.primaryFontFamily,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isActive
                                      ? theme.scaffoldBackground
                                      : theme.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '${_activeDays.length} active day${_activeDays.length != 1 ? 's' : ''} / week',
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.mutedText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _timeOfDayIcon(StudyTimeOfDay t) {
    return switch (t) {
      StudyTimeOfDay.fajr => LucideIcons.sunrise,
      StudyTimeOfDay.morning => LucideIcons.sun,
      StudyTimeOfDay.afternoon => LucideIcons.cloudSun,
      StudyTimeOfDay.evening => LucideIcons.sunset,
      StudyTimeOfDay.night => LucideIcons.moon,
    };
  }

  String _timeOfDayLabel(StudyTimeOfDay t) {
    switch (t) {
      case StudyTimeOfDay.fajr:
        return 'Fajr';
      case StudyTimeOfDay.morning:
        return 'Morning';
      case StudyTimeOfDay.afternoon:
        return 'Afternoon';
      case StudyTimeOfDay.evening:
        return 'Evening';
      case StudyTimeOfDay.night:
        return 'Night';
    }
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // PAGE 4: GOAL (goal + pace + starting point)
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget _buildGoalPage(ThemeProvider theme) {
    return _pageWrapper(
      theme,
      icon: LucideIcons.target,
      title: AppLocalizations.of(context)!.assessGoalPace,
      subtitle: AppLocalizations.of(context)!.assessWhatMemorize,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Goal
          _sectionLabel(theme, AppLocalizations.of(context)!.assessWhatAim, ''),
          const SizedBox(height: 8),
          _segmentedPills<HifzGoal>(
            theme,
            values: HifzGoal.values,
            selected: _goal,
            labels: {
              HifzGoal.fullQuran: 'Full Quran',
              HifzGoal.specificJuz: 'Juz',
              HifzGoal.specificSurahs: 'Surahs',
            },
            icons: {
              HifzGoal.fullQuran: LucideIcons.bookOpen,
              HifzGoal.specificJuz: LucideIcons.fileStack,
              HifzGoal.specificSurahs: LucideIcons.fileText,
            },
            onChanged: (v) => setState(() => _goal = v),
          ),
          const SizedBox(height: 24),
          // Pace
          _sectionLabel(theme, AppLocalizations.of(context)!.assessHowFast, ''),
          const SizedBox(height: 8),
          _segmentedPills<PacePreference>(
            theme,
            values: PacePreference.values,
            selected: _pacePreference,
            labels: {
              PacePreference.aggressive: 'Push Me',
              PacePreference.steady: 'Steady',
              PacePreference.gentle: 'Gentle',
            },
            icons: {
              PacePreference.aggressive: LucideIcons.rocket,
              PacePreference.steady: LucideIcons.scale,
              PacePreference.gentle: LucideIcons.leaf,
            },
            onChanged: (v) => setState(() => _pacePreference = v),
          ),
          const SizedBox(height: 24),
          // Starting Point
          _sectionLabel(
            theme,
            AppLocalizations.of(context)!.assessWhereStart,
            '',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pillChip(
                theme,
                LucideIcons.star,
                'Juz 30 (p.582)',
                _startingPage == 582,
                () => setState(() => _startingPage = 582),
              ),
              _pillChip(
                theme,
                LucideIcons.star,
                'Al-Baqarah (p.2)',
                _startingPage == 2,
                () => setState(() => _startingPage = 2),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Custom page input
          Row(
            children: [
              Text(
                'Or page:',
                style: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 12,
                  color: theme.mutedText,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: GeistTypography.primaryFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryText,
                  ),
                  decoration: InputDecoration(
                    hintText: '$_startingPage',
                    hintStyle: TextStyle(color: theme.mutedText, fontSize: 14),
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (v) {
                    final page = int.tryParse(v);
                    if (page != null && page >= 1 && page <= 604) {
                      setState(() => _startingPage = page);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // PAGE 5: RECITER (with audio preview)
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Future<void> _playSample(int reciterId) async {
    try {
      // Stop current playback
      await _samplePlayer.stop();
      setState(() => _playingReciterId = reciterId);
      // Play Surah Al-Fatiha as a sample
      final url =
          'https://api.quran.com/api/v4/chapter_recitations/$reciterId/1';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final audioUrl = data['audio_file']?['audio_url'] as String?;
        if (audioUrl != null) {
          final fullUrl = audioUrl.startsWith('http')
              ? audioUrl
              : 'https://audio.qurancdn.com/$audioUrl';
          final finalUrl = Platform.isWindows
              ? AudioProxyServer().proxyUrl(fullUrl)
              : fullUrl;
          await _samplePlayer.play(UrlSource(finalUrl));
          // Stop after 10 seconds for a short preview
          Future.delayed(const Duration(seconds: 10), () {
            if (_playingReciterId == reciterId && mounted) {
              _samplePlayer.stop();
              setState(() => _playingReciterId = null);
            }
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _playingReciterId = null);
    }
  }

  Widget _buildReciterPage(ThemeProvider theme) {
    final readingProvider = context.watch<QuranReadingProvider>();
    final reciters = readingProvider.reciters;

    return _pageWrapper(
      theme,
      icon: LucideIcons.mic,
      title: AppLocalizations.of(context)!.assessChooseQari,
      subtitle: AppLocalizations.of(context)!.assessStickingOne,
      child: readingProvider.isLoadingReciters && reciters.isEmpty
          ? Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    color: theme.primaryText,
                    strokeWidth: 2,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.assessLoadingReciters,
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 13,
                      color: theme.mutedText,
                    ),
                  ),
                ],
              ),
            )
          : reciters.isEmpty && readingProvider.recitersError.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.wifiOff,
                      size: 48,
                      color: theme.dividerColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.reciterNoFound,
                      style: TextStyle(
                        fontFamily: GeistTypography.primaryFontFamily,
                        fontSize: 13,
                        color: theme.mutedText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => readingProvider.loadReciters(),
                      icon: const Icon(LucideIcons.refreshCw, size: 16),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : SizedBox(
              height: 320,
              child: ListView.separated(
                itemCount: reciters.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (ctx, i) {
                  final reciter = reciters[i];
                  final isSelected = _selectedReciterId == reciter.id;
                  final isPlaying = _playingReciterId == reciter.id;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedReciterId = reciter.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? theme.primaryText : theme.cardColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryText.withValues(alpha: 0.08),
                            blurRadius: 0,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Reciter avatar
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? theme.scaffoldBackground.withValues(
                                      alpha: 0.2,
                                    )
                                  : theme.dividerColor.withValues(alpha: 0.3),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/reciters/${reciter.id}.jpg',
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Center(
                                  child: Text(
                                    reciter.reciterName.isNotEmpty
                                        ? reciter.reciterName
                                              .trim()
                                              .characters
                                              .first
                                        : '?',
                                    style: TextStyle(
                                      fontFamily:
                                          GeistTypography.primaryFontFamily,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isSelected
                                          ? theme.scaffoldBackground
                                          : theme.mutedText,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reciter.reciterName,
                                  style: TextStyle(
                                    fontFamily:
                                        GeistTypography.primaryFontFamily,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? theme.scaffoldBackground
                                        : theme.primaryText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (reciter.style != null)
                                  Text(
                                    reciter.style!,
                                    style: TextStyle(
                                      fontFamily:
                                          GeistTypography.primaryFontFamily,
                                      fontSize: 10,
                                      color: isSelected
                                          ? theme.scaffoldBackground.withValues(
                                              alpha: 0.7,
                                            )
                                          : theme.mutedText,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Play sample button
                          GestureDetector(
                            onTap: () {
                              if (isPlaying) {
                                _samplePlayer.stop();
                                setState(() => _playingReciterId = null);
                              } else {
                                _playSample(reciter.id);
                              }
                            },
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isPlaying
                                    ? (isSelected
                                          ? theme.scaffoldBackground
                                          : theme.primaryText)
                                    : Colors.transparent,
                              ),
                              child: Icon(
                                isPlaying
                                    ? LucideIcons.pause
                                    : LucideIcons.play,
                                size: 14,
                                color: isPlaying
                                    ? (isSelected
                                          ? theme.primaryText
                                          : theme.scaffoldBackground)
                                    : (isSelected
                                          ? theme.scaffoldBackground
                                          : theme.mutedText),
                              ),
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 6),
                            Icon(
                              LucideIcons.checkCircle2,
                              size: 18,
                              color: theme.scaffoldBackground,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // PAGE 9: SUMMARY
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget _buildSummaryPage(ThemeProvider theme) {
    // Pre-compute plan params for the summary
    final load = _computeDailyLoad();
    final timeSplit = _computeTimeSplit();
    final timeline = _computeTimeline(load);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              // Avatar + Name
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: theme.accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.accentColor, width: 2),
                ),
                child: Center(
                  child: Icon(
                    IconResolver.avatarIcons[_avatarIndex],
                    size: 36,
                    color: theme.accentColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _name.trim(),
                style: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: theme.primaryText,
                ),
              ),
              const SizedBox(height: 24),

              // â”€â”€ 2-Axis Memory Profile â”€â”€
              _buildProfileChart(theme),
              const SizedBox(height: 16),

              // â”€â”€ Your Plan â”€â”€
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.assessYourPlan,
                      style: TextStyle(
                        fontFamily: GeistTypography.primaryFontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _paramRow(
                      theme,
                      LucideIcons.cake,
                      'Age',
                      '${MemoryProfile.calculateAge(_birthday)} (${_ageGroup.name})',
                    ),
                    const SizedBox(height: 10),
                    _paramRow(
                      theme,
                      LucideIcons.sprout,
                      'Experience',
                      _hifzExperience.name,
                    ),
                    const SizedBox(height: 10),
                    _paramRow(
                      theme,
                      LucideIcons.calendarDays,
                      AppLocalizations.of(context)!.assessActiveDays,
                      '${_activeDays.length}/7 days',
                    ),
                    const SizedBox(height: 10),
                    _paramRow(
                      theme,
                      LucideIcons.zap,
                      'Pace',
                      _pacePreference.name,
                    ),
                    const SizedBox(height: 10),
                    _paramRow(
                      theme,
                      LucideIcons.bookOpen,
                      AppLocalizations.of(context)!.assessDailyNew,
                      load,
                    ),
                    const SizedBox(height: 10),
                    _paramRow(
                      theme,
                      LucideIcons.repeat,
                      AppLocalizations.of(context)!.assessTargetReps,
                      _targetRepsDescription(),
                    ),
                    const SizedBox(height: 10),
                    _paramRow(
                      theme,
                      LucideIcons.clock,
                      AppLocalizations.of(context)!.assessTimeSplit,
                      timeSplit,
                    ),
                    const SizedBox(height: 10),
                    _paramRow(
                      theme,
                      LucideIcons.mapPin,
                      AppLocalizations.of(context)!.assessStartingAt,
                      'Page $_startingPage',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // â”€â”€ Estimated Timeline â”€â”€
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.accentColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.target,
                      size: 22,
                      color: theme.accentColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.assessEstTimeline,
                            style: TextStyle(
                              fontFamily: GeistTypography.primaryFontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: theme.accentColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeline,
                            style: TextStyle(
                              fontFamily: GeistTypography.primaryFontFamily,
                              fontSize: 12,
                              color: theme.accentColor.withValues(alpha: 0.8),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // â”€â”€ Start Button â”€â”€
              SizedBox(
                width: double.infinity,
                child: GeistButton(
                  onPressed: _createProfile,
                  label: AppLocalizations.of(context)!.assessStartJourney,
                  type: GeistButtonType.primary,
                  size: GeistButtonSize.large,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // â”€â”€ 2-Axis Memory Profile Chart â”€â”€

  Widget _buildProfileChart(ThemeProvider theme) {
    // Map encoding/retention to 0.0-1.0 positions
    final encX = switch (_encodingSpeed) {
      EncodingSpeed.slow => 0.15,
      EncodingSpeed.moderate => 0.50,
      EncodingSpeed.fast => 0.85,
    };
    final retY = switch (_retention) {
      RetentionStrength.fragile => 0.85,
      RetentionStrength.moderate => 0.50,
      RetentionStrength.strong => 0.15,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.assessYourProfile,
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          // Chart
          SizedBox(
            height: 140,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                const h = 140.0;
                const pad = 28.0; // space for labels
                final chartW = w - pad;
                final chartH = h - pad;

                return Stack(
                  children: [
                    // Grid background
                    Positioned(
                      left: pad,
                      top: 0,
                      width: chartW,
                      height: chartH,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.dividerColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.dividerColor.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                    // Y-axis label (top)
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Icon(
                        LucideIcons.dumbbell,
                        size: 11,
                        color: theme.mutedText,
                      ),
                    ),
                    // Y-axis label (bottom)
                    Positioned(
                      left: 0,
                      top: chartH - 14,
                      child: Icon(
                        LucideIcons.helpCircle,
                        size: 11,
                        color: theme.mutedText,
                      ),
                    ),
                    // X-axis label (left)
                    Positioned(
                      left: pad + 2,
                      bottom: 0,
                      child: Icon(
                        LucideIcons.gauge,
                        size: 11,
                        color: theme.mutedText,
                      ),
                    ),
                    // X-axis label (right)
                    Positioned(
                      right: 2,
                      bottom: 0,
                      child: Icon(
                        LucideIcons.rocket,
                        size: 11,
                        color: theme.mutedText,
                      ),
                    ),
                    // User dot
                    Positioned(
                      left: pad + (chartW * encX) - 14,
                      top: (chartH * retY) - 14,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: theme.accentColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: theme.shadowCard,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _chipLabel(theme, 'Speed: ${_encodingSpeed.name}'),
              _chipLabel(theme, 'Retention: ${_retention.name}'),
              _chipLabel(theme, _learningPref.name),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chipLabel(ThemeProvider theme, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text[0].toUpperCase() + text.substring(1),
        style: TextStyle(
          fontFamily: GeistTypography.primaryFontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: theme.accentColor,
        ),
      ),
    );
  }

  // â”€â”€ Plan Calculations (from plan-generation.md Â§ Step 2) â”€â”€

  /// Daily load using the full time Ã— encoding speed table.
  /// Daily load as a fixed amount (not a range) â€” pace determines the value.
  /// Steady = base amount, aggressive = higher, gentle = lower.
  String _computeDailyLoad() {
    // Base lines from time Ã— encoding speed
    int baseLines;
    if (_dailyMinutes <= 30) {
      baseLines = switch (_encodingSpeed) {
        EncodingSpeed.fast => 8,
        EncodingSpeed.moderate => 5,
        EncodingSpeed.slow => 3,
      };
    } else if (_dailyMinutes <= 60) {
      baseLines = switch (_encodingSpeed) {
        EncodingSpeed.fast => 15,
        EncodingSpeed.moderate => 8,
        EncodingSpeed.slow => 5,
      };
    } else if (_dailyMinutes <= 120) {
      baseLines = switch (_encodingSpeed) {
        EncodingSpeed.fast => 30,
        EncodingSpeed.moderate => 15,
        EncodingSpeed.slow => 8,
      };
    } else {
      baseLines = switch (_encodingSpeed) {
        EncodingSpeed.fast => 45,
        EncodingSpeed.moderate => 30,
        EncodingSpeed.slow => 15,
      };
    }

    // Pace adjustment
    switch (_pacePreference) {
      case PacePreference.aggressive:
        baseLines = (baseLines * 1.3).round();
        break;
      case PacePreference.gentle:
        baseLines = (baseLines * 0.7).round();
        break;
      case PacePreference.steady:
        break; // Use base
    }

    // Format as pages or lines
    if (baseLines >= 30) {
      return '${(baseLines / 15).toStringAsFixed(0)} pages';
    } else if (baseLines >= 15) {
      return '1 page (15 lines)';
    } else {
      return '$baseLines lines';
    }
  }

  /// Time distribution across phases.
  String _computeTimeSplit() {
    final sabaq = (_dailyMinutes * 0.45).round();
    final sabqi = (_dailyMinutes * 0.30).round();
    final manzil = _dailyMinutes - sabaq - sabqi;
    return '${sabaq}m / ${sabqi}m / ${manzil}m';
  }

  /// Estimated timeline based on goal + daily load.
  String _computeTimeline(String loadText) {
    // Approximate pages per day from the load text
    double pagesPerDay;
    if (loadText.contains('2-3 pages')) {
      pagesPerDay = 2.5;
    } else if (loadText.contains('1-2 pages')) {
      pagesPerDay = 1.5;
    } else if (loadText.contains('1 page')) {
      pagesPerDay = 1.0;
    } else if (loadText.contains('Â½')) {
      pagesPerDay = 0.5;
    } else if (loadText.contains('5-8 lines')) {
      pagesPerDay = 0.4; // ~6 lines â‰ˆ 0.4 pages
    } else if (loadText.contains('3-5 lines')) {
      pagesPerDay = 0.25;
    } else if (loadText.contains('2-3 lines')) {
      pagesPerDay = 0.15;
    } else {
      pagesPerDay = 0.5;
    }

    // Calculate total pages based on goal
    int totalPages;
    switch (_goal) {
      case HifzGoal.fullQuran:
        totalPages = 604;
        break;
      case HifzGoal.specificJuz:
        totalPages = _goalDetails.isEmpty ? 20 : _goalDetails.length * 20;
        break;
      case HifzGoal.specificSurahs:
        totalPages = _goalDetails.isEmpty
            ? 10
            : _goalDetails.length * 5; // rough
        break;
    }

    // Account for active days per week
    final activeDaysPerWeek = _activeDays.length.clamp(1, 7);
    final totalDays = totalPages / (pagesPerDay * activeDaysPerWeek / 7);
    final months = totalDays / 30;

    String goalLabel;
    switch (_goal) {
      case HifzGoal.fullQuran:
        goalLabel = 'the entire Quran';
        break;
      case HifzGoal.specificJuz:
        goalLabel = '${_goalDetails.isEmpty ? 1 : _goalDetails.length} juz';
        break;
      case HifzGoal.specificSurahs:
        goalLabel = 'your selected surahs';
        break;
    }

    if (months < 1.5) {
      return 'At $_dailyMinutes min/day, you could complete $goalLabel in ~${(totalDays / 7).round()} weeks';
    } else if (months < 12) {
      return 'At $_dailyMinutes min/day, you could complete $goalLabel in ~${months.round()} months';
    } else {
      final years = months / 12;
      return 'At $_dailyMinutes min/day, you could complete $goalLabel in ~${years.toStringAsFixed(1)} years';
    }
  }

  /// Research-based repetition targets â€” real hifz pedagogy requires
  /// high repetitions for lasting memorization.
  String _targetRepsDescription() {
    if (_encodingSpeed == EncodingSpeed.slow ||
        _retention == RetentionStrength.fragile) {
      return '30+ per section';
    }
    if (_encodingSpeed == EncodingSpeed.fast &&
        _retention == RetentionStrength.strong) {
      return '15 per section';
    }
    return '20 per section';
  }

  Widget _paramRow(
    ThemeProvider theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.accentColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 13,
              color: theme.secondaryText,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.primaryText,
            ),
          ),
        ),
      ],
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // SHARED WIDGETS
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  /// Standard page layout wrapper with title, subtitle, content, and continue button.
  Widget _pageWrapper(
    ThemeProvider theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
    bool canProceed = true,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 24, color: theme.accentColor),
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                title,
                style: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: theme.primaryText,
                  letterSpacing: -0.3,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: theme.secondaryText,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              // Content
              child,
              const SizedBox(height: 32),
              // Continue button
              SizedBox(
                width: double.infinity,
                child: GeistButton(
                  onPressed: canProceed ? _nextPage : null,
                  label: AppLocalizations.of(context)!.assessContinue,
                  type: GeistButtonType.primary,
                  size: GeistButtonSize.large,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Reusable option card for single/multi selection.
  Widget _optionCard(
    ThemeProvider theme,
    IconData icon,
    String title,
    String subtitle,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.accentColor.withValues(alpha: 0.08)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? theme.accentColor : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? theme.accentColor : theme.secondaryText,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? theme.accentColor : theme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 12,
                      color: theme.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                LucideIcons.checkCircle2,
                size: 20,
                color: theme.accentColor,
              ),
          ],
        ),
      ),
    );
  }
}
