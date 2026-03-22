import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/providers/hifz_profile_provider.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';

/// 9-screen assessment wizard for creating a Hifz memory profile.
/// Collects: name/avatar → age → learning pref → encoding speed →
/// retention → schedule+goal → reciter → starting point → summary.
class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  static const _totalPages = 9;

  // ── Collected data ──
  String _name = '';
  int _avatarIndex = 0;
  AgeGroup _ageGroup = AgeGroup.adult;
  LearningPreference _learningPref = LearningPreference.visual;
  EncodingSpeed _encodingSpeed = EncodingSpeed.moderate;
  RetentionStrength _retention = RetentionStrength.moderate;
  int _dailyMinutes = 30;
  StudyTimeOfDay _timeOfDay = StudyTimeOfDay.fajr;
  HifzGoal _goal = HifzGoal.fullQuran;
  List<int> _goalDetails = [];
  int _startingPage = 582; // Juz 30
  int _selectedReciterId = 7; // Mishary al-Afasy (default)

  final _nameController = TextEditingController();
  String? _existingProfileId;
  DateTime? _existingCreatedAt;

  @override
  void initState() {
    super.initState();
    // Pre-populate from existing profile if retaking assessment
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = context.read<HifzProfileProvider>();
      if (profileProvider.hasActiveProfile) {
        final p = profileProvider.activeProfile!;
        setState(() {
          _existingProfileId = p.id;
          _existingCreatedAt = p.createdAt;
          _name = p.name;
          _nameController.text = p.name;
          _avatarIndex = p.avatarIndex;
          _ageGroup = p.ageGroup;
          _learningPref = p.learningPreference;
          _encodingSpeed = p.encodingSpeed;
          _retention = p.retentionStrength;
          _dailyMinutes = p.dailyTimeMinutes;
          _timeOfDay = p.preferredTimeOfDay;
          _goal = p.goal;
          _goalDetails = p.goalDetails;
          _startingPage = p.startingPage;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
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
    final profile = MemoryProfile(
      id: _existingProfileId ?? '${now.millisecondsSinceEpoch}',
      name: _name.trim(),
      avatarIndex: _avatarIndex,
      createdAt: _existingCreatedAt ?? now,
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
    );
    if (_existingProfileId != null) {
      // Retake: update existing profile, keep all progress
      await profileProvider.updateProfile(profile);
    } else {
      await profileProvider.createProfile(profile);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar: back + progress ──
            _buildTopBar(theme),
            // ── Page content ──
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildWelcomePage(theme),
                  _buildAgeGroupPage(theme),
                  _buildLearningPrefPage(theme),
                  _buildEncodingSpeedPage(theme),
                  _buildRetentionPage(theme),
                  _buildScheduleGoalPage(theme),
                  _buildReciterPage(theme),
                  _buildStartingPointPage(theme),
                  _buildSummaryPage(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════
  // TOP BAR
  // ════════════════════════════════

  Widget _buildTopBar(ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (_currentPage > 0)
            GestureDetector(
              onTap: _prevPage,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Icon(
                  LucideIcons.arrowLeft,
                  size: 18,
                  color: theme.primaryText,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Icon(
                  LucideIcons.x,
                  size: 18,
                  color: theme.primaryText,
                ),
              ),
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
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════
  // PAGE 1: WELCOME
  // ════════════════════════════════

  Widget _buildWelcomePage(ThemeProvider theme) {
    return _pageWrapper(
      theme,
      icon: LucideIcons.sparkles,
      title: 'Let\'s build your Hifz profile',
      subtitle: 'A few quick questions to personalize your journey',
      child: Column(
        children: [
          // Name input
          TextField(
            controller: _nameController,
            onChanged: (v) => setState(() => _name = v),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: theme.primaryText,
            ),
            decoration: InputDecoration(
              hintText: 'What should we call you?',
              hintStyle: TextStyle(
                fontFamily: 'Inter',
                color: theme.mutedText,
              ),
              filled: true,
              fillColor: theme.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: theme.accentColor, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Avatar picker
          Text(
            'Choose an avatar',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.secondaryText,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _avatarEmojis.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final isSelected = _avatarIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _avatarIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.accentColor.withValues(alpha: 0.15)
                          : theme.cardColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? theme.accentColor
                            : theme.dividerColor,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _avatarEmojis[i],
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      canProceed: _name.trim().isNotEmpty,
    );
  }

  static const _avatarEmojis = [
    '🌙', '⭐', '📖', '🕌', '🌿', '🕋', '💎', '🌸',
  ];

  // ════════════════════════════════
  // PAGE 2: AGE GROUP
  // ════════════════════════════════

  Widget _buildAgeGroupPage(ThemeProvider theme) {
    return _pageWrapper(
      theme,
      icon: LucideIcons.users,
      title: 'How old are you?',
      subtitle: 'This helps us tailor the experience',
      child: Column(
        children: [
          _optionCard(theme, '🧒', 'Child', '7-12 years',
              _ageGroup == AgeGroup.child, () => setState(() => _ageGroup = AgeGroup.child)),
          const SizedBox(height: 12),
          _optionCard(theme, '🧑', 'Teen', '13-17 years',
              _ageGroup == AgeGroup.teen, () => setState(() => _ageGroup = AgeGroup.teen)),
          const SizedBox(height: 12),
          _optionCard(theme, '🧔', 'Adult', '18+',
              _ageGroup == AgeGroup.adult, () => setState(() => _ageGroup = AgeGroup.adult)),
        ],
      ),
    );
  }

  // ════════════════════════════════
  // PAGE 3: LEARNING PREFERENCE
  // ════════════════════════════════

  Widget _buildLearningPrefPage(ThemeProvider theme) {
    return _pageWrapper(
      theme,
      icon: LucideIcons.brain,
      title: 'When you memorize something new, what helps most?',
      subtitle: 'Pick the one that resonates — no wrong answers!',
      child: Column(
        children: [
          _optionCard(theme, '👁️', 'Looking and reading',
              'I stare at the text until it sticks',
              _learningPref == LearningPreference.visual,
              () => setState(() => _learningPref = LearningPreference.visual)),
          const SizedBox(height: 12),
          _optionCard(theme, '👂', 'Listening',
              'I listen to it over and over',
              _learningPref == LearningPreference.auditory,
              () => setState(() => _learningPref = LearningPreference.auditory)),
          const SizedBox(height: 12),
          _optionCard(theme, '✍️', 'Writing it down',
              'Writing helps me remember',
              _learningPref == LearningPreference.kinesthetic,
              () => setState(() => _learningPref = LearningPreference.kinesthetic)),
          const SizedBox(height: 12),
          _optionCard(theme, '🔄', 'Repeating out loud',
              'I just keep saying it until I know it',
              _learningPref == LearningPreference.repetition,
              () => setState(() => _learningPref = LearningPreference.repetition)),
        ],
      ),
    );
  }

  // ════════════════════════════════
  // PAGE 4: ENCODING SPEED
  // ════════════════════════════════

  Widget _buildEncodingSpeedPage(ThemeProvider theme) {
    return _pageWrapper(
      theme,
      icon: LucideIcons.zap,
      title: 'Imagine memorizing a new page...',
      subtitle: 'After 30 minutes of focused effort, how much would you typically remember?',
      child: Column(
        children: [
          _optionCard(theme, '🚀', 'Most of the page',
              'I pick things up quickly',
              _encodingSpeed == EncodingSpeed.fast,
              () => setState(() => _encodingSpeed = EncodingSpeed.fast)),
          const SizedBox(height: 12),
          _optionCard(theme, '📖', 'About half',
              'I need a few sessions to finish a page',
              _encodingSpeed == EncodingSpeed.moderate,
              () => setState(() => _encodingSpeed = EncodingSpeed.moderate)),
          const SizedBox(height: 12),
          _optionCard(theme, '🐢', 'A few lines',
              'I prefer to go slow and careful',
              _encodingSpeed == EncodingSpeed.slow,
              () => setState(() => _encodingSpeed = EncodingSpeed.slow)),
        ],
      ),
    );
  }

  // ════════════════════════════════
  // PAGE 5: RETENTION
  // ════════════════════════════════

  Widget _buildRetentionPage(ThemeProvider theme) {
    return _pageWrapper(
      theme,
      icon: LucideIcons.refreshCw,
      title: 'Think about something you memorized last month...',
      subtitle: 'If someone asked you to recite it today, how would it go?',
      child: Column(
        children: [
          _optionCard(theme, '💪', 'Pretty smoothly',
              'It sticks with me once I learn it',
              _retention == RetentionStrength.strong,
              () => setState(() => _retention = RetentionStrength.strong)),
          const SizedBox(height: 12),
          _optionCard(theme, '🤔', 'I\'d need a quick refresh',
              'Then it comes back',
              _retention == RetentionStrength.moderate,
              () => setState(() => _retention = RetentionStrength.moderate)),
          const SizedBox(height: 12),
          _optionCard(theme, '😅', 'I\'d struggle',
              'Things fade if I don\'t review regularly',
              _retention == RetentionStrength.fragile,
              () => setState(() => _retention = RetentionStrength.fragile)),
        ],
      ),
    );
  }

  // ════════════════════════════════
  // PAGE 6: SCHEDULE + GOAL
  // ════════════════════════════════

  Widget _buildScheduleGoalPage(ThemeProvider theme) {
    return _pageWrapper(
      theme,
      icon: LucideIcons.clock,
      title: 'Your daily commitment',
      subtitle: 'How much time and what\'s your goal?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time slider
          Text(
            'Daily time: $_dailyMinutes minutes',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _dailyMinutes.toDouble(),
            min: 15,
            max: 240,
            divisions: 15,
            activeColor: theme.accentColor,
            inactiveColor: theme.dividerColor,
            label: '$_dailyMinutes min',
            onChanged: (v) => setState(() => _dailyMinutes = v.round()),
          ),
          const SizedBox(height: 16),
          // Time of day chips
          Text(
            'Preferred time',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: StudyTimeOfDay.values.map((t) {
              final isSelected = _timeOfDay == t;
              return GestureDetector(
                onTap: () => setState(() => _timeOfDay = t),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.accentColor.withValues(alpha: 0.15)
                        : theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? theme.accentColor : theme.dividerColor,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    _timeOfDayLabel(t),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? theme.accentColor : theme.secondaryText,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          // Goal selection
          Text(
            'What\'s your aim?',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          _optionCard(theme, '📖', 'The entire Quran', 'Full memorization journey',
              _goal == HifzGoal.fullQuran,
              () => setState(() => _goal = HifzGoal.fullQuran)),
          const SizedBox(height: 10),
          _optionCard(theme, '📑', 'Specific Juz', 'Choose which juz to memorize',
              _goal == HifzGoal.specificJuz,
              () => setState(() => _goal = HifzGoal.specificJuz)),
          const SizedBox(height: 10),
          _optionCard(theme, '📄', 'Specific Surahs', 'Pick individual surahs',
              _goal == HifzGoal.specificSurahs,
              () => setState(() => _goal = HifzGoal.specificSurahs)),
        ],
      ),
    );
  }

  String _timeOfDayLabel(StudyTimeOfDay t) {
    switch (t) {
      case StudyTimeOfDay.fajr: return '🌅 Fajr';
      case StudyTimeOfDay.morning: return '☀️ Morning';
      case StudyTimeOfDay.afternoon: return '🌤️ Afternoon';
      case StudyTimeOfDay.evening: return '🌆 Evening';
      case StudyTimeOfDay.night: return '🌙 Night';
    }
  }

  // ════════════════════════════════
  // PAGE 7: RECITER (simplified)
  // ════════════════════════════════

  Widget _buildReciterPage(ThemeProvider theme) {
    final readingProvider = context.watch<QuranReadingProvider>();
    final reciters = readingProvider.reciters;

    return _pageWrapper(
      theme,
      icon: LucideIcons.mic,
      title: 'Choose your Qari',
      subtitle: 'Sticking with one reciter helps build stronger auditory memory',
      child: reciters.isEmpty
          ? Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: theme.accentColor),
                  const SizedBox(height: 12),
                  Text(
                    'Loading reciters...',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: theme.mutedText,
                    ),
                  ),
                ],
              ),
            )
          : SizedBox(
              height: 320,
              child: ListView.separated(
                itemCount: reciters.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final reciter = reciters[i];
                  final isSelected = _selectedReciterId == reciter.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedReciterId = reciter.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.accentColor.withValues(alpha: 0.1)
                            : theme.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? theme.accentColor
                              : theme.dividerColor,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Reciter avatar
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.cardColor,
                              border: Border.all(color: theme.dividerColor),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/reciters/${reciter.id}.jpg',
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    reciter.reciterName.isNotEmpty
                                        ? reciter.reciterName
                                            .trim()
                                            .characters
                                            .first
                                        : '?',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: theme.mutedText,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reciter.reciterName,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? theme.accentColor
                                        : theme.primaryText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (reciter.style != null)
                                  Text(
                                    reciter.style!,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      color: theme.mutedText,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(LucideIcons.checkCircle2,
                                size: 20, color: theme.accentColor),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  // ════════════════════════════════
  // PAGE 8: STARTING POINT
  // ════════════════════════════════

  Widget _buildStartingPointPage(ThemeProvider theme) {
    return _pageWrapper(
      theme,
      icon: LucideIcons.mapPin,
      title: 'Where would you like to start?',
      subtitle: 'Pick any page or surah — you\'re in full control',
      child: Column(
        children: [
          // Suggested options
          _optionCard(theme, '⭐', 'Juz 30 (Juz \'Amma)',
              'Most common starting point — Page 582',
              _startingPage == 582,
              () => setState(() => _startingPage = 582)),
          const SizedBox(height: 12),
          _optionCard(theme, '⭐', 'Surah Al-Baqarah',
              'Start from the beginning — Page 2',
              _startingPage == 2,
              () => setState(() => _startingPage = 2)),
          const SizedBox(height: 20),
          // Custom page input
          Text(
            'Or pick a specific page (1-604)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: theme.secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 120,
            child: TextField(
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.primaryText,
              ),
              decoration: InputDecoration(
                hintText: '$_startingPage',
                hintStyle: TextStyle(color: theme.mutedText),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.accentColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
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
    );
  }

  // ════════════════════════════════
  // PAGE 9: SUMMARY
  // ════════════════════════════════

  Widget _buildSummaryPage(ThemeProvider theme) {
    // Pre-compute plan params for the summary
    final load = _computeDailyLoad();
    final timeSplit = _computeTimeSplit();
    final timeline = _computeTimeline(load);

    return SingleChildScrollView(
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
              child: Text(
                _avatarEmojis[_avatarIndex],
                style: const TextStyle(fontSize: 36),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _name.trim(),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 24),

          // ── 2-Axis Memory Profile ──
          _buildProfileChart(theme),
          const SizedBox(height: 16),

          // ── Your Plan ──
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
                  'Your Plan',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.primaryText,
                  ),
                ),
                const SizedBox(height: 16),
                _paramRow(theme, '📖', 'Daily new material', load),
                const SizedBox(height: 10),
                _paramRow(theme, '🔁', 'Target repetitions',
                    _targetRepsDescription()),
                const SizedBox(height: 10),
                _paramRow(theme, '⏱', 'Time split', timeSplit),
                const SizedBox(height: 10),
                _paramRow(theme, '📍', 'Starting at', 'Page $_startingPage'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Estimated Timeline ──
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
                Text('🎯', style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated Timeline',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: theme.accentColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeline,
                        style: TextStyle(
                          fontFamily: 'Inter',
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

          // ── Start Button ──
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _createProfile,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: theme.accentColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: theme.accentColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'Start My Journey ✨',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── 2-Axis Memory Profile Chart ──

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
            'Your Memory Profile',
            style: TextStyle(
              fontFamily: 'Inter',
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
                      child: Text('💪',
                          style: TextStyle(
                              fontSize: 11, color: theme.mutedText)),
                    ),
                    // Y-axis label (bottom)
                    Positioned(
                      left: 0,
                      top: chartH - 14,
                      child: Text('😅',
                          style: TextStyle(
                              fontSize: 11, color: theme.mutedText)),
                    ),
                    // X-axis label (left)
                    Positioned(
                      left: pad + 2,
                      bottom: 0,
                      child: Text('🐢',
                          style: TextStyle(
                              fontSize: 11, color: theme.mutedText)),
                    ),
                    // X-axis label (right)
                    Positioned(
                      right: 2,
                      bottom: 0,
                      child: Text('🚀',
                          style: TextStyle(
                              fontSize: 11, color: theme.mutedText)),
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
                          boxShadow: [
                            BoxShadow(
                              color:
                                  theme.accentColor.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
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
              _chipLabel(theme, '${_learningPref.name}'),
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
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: theme.accentColor,
        ),
      ),
    );
  }

  // ── Plan Calculations (from plan-generation.md § Step 2) ──

  /// Daily load using the full time × encoding speed table.
  String _computeDailyLoad() {
    if (_dailyMinutes <= 30) {
      return switch (_encodingSpeed) {
        EncodingSpeed.fast => '5-8 lines',
        EncodingSpeed.moderate => '3-5 lines',
        EncodingSpeed.slow => '2-3 lines',
      };
    } else if (_dailyMinutes <= 60) {
      return switch (_encodingSpeed) {
        EncodingSpeed.fast => '½ – 1 page',
        EncodingSpeed.moderate => '5-8 lines',
        EncodingSpeed.slow => '3-5 lines',
      };
    } else if (_dailyMinutes <= 120) {
      return switch (_encodingSpeed) {
        EncodingSpeed.fast => '1-2 pages',
        EncodingSpeed.moderate => '½ – 1 page',
        EncodingSpeed.slow => '5-8 lines',
      };
    } else {
      return switch (_encodingSpeed) {
        EncodingSpeed.fast => '2-3 pages',
        EncodingSpeed.moderate => '1-2 pages',
        EncodingSpeed.slow => '½ – 1 page',
      };
    }
  }

  /// Time distribution across phases.
  String _computeTimeSplit() {
    final sabaq = (_dailyMinutes * 0.45).round();
    final sabqi = (_dailyMinutes * 0.30).round();
    final manzil = _dailyMinutes - sabaq - sabqi;
    return '${sabaq}m new / ${sabqi}m review / ${manzil}m manzil';
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
    } else if (loadText.contains('½')) {
      pagesPerDay = 0.5;
    } else if (loadText.contains('5-8 lines')) {
      pagesPerDay = 0.4; // ~6 lines ≈ 0.4 pages
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
        totalPages = _goalDetails.isEmpty ? 10 : _goalDetails.length * 5; // rough
        break;
    }

    final totalDays = totalPages / pagesPerDay;
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

  String _targetRepsDescription() {
    if (_encodingSpeed == EncodingSpeed.slow || _retention == RetentionStrength.fragile) {
      return '15+ per section';
    }
    if (_encodingSpeed == EncodingSpeed.fast && _retention == RetentionStrength.strong) {
      return '5-7 per section';
    }
    return '10 per section';
  }


  Widget _paramRow(ThemeProvider theme, String emoji, String label, String value) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: theme.secondaryText,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.primaryText,
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════
  // SHARED WIDGETS
  // ════════════════════════════════

  /// Standard page layout wrapper with title, subtitle, content, and continue button.
  Widget _pageWrapper(
    ThemeProvider theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
    bool canProceed = true,
  }) {
    return SingleChildScrollView(
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
              fontFamily: 'Inter',
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
              fontFamily: 'Inter',
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
            child: GestureDetector(
              onTap: canProceed ? _nextPage : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: canProceed
                      ? theme.accentColor
                      : theme.accentColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Continue →',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: canProceed
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Reusable option card for single/multi selection.
  Widget _optionCard(
    ThemeProvider theme,
    String emoji,
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
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? theme.accentColor
                          : theme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: theme.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(LucideIcons.checkCircle2, size: 20, color: theme.accentColor),
          ],
        ),
      ),
    );
  }
}
