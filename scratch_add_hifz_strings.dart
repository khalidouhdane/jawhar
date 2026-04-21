import 'dart:convert';
import 'dart:io';

void main() {
  final enFile = File('lib/l10n/app_en.arb');
  final arFile = File('lib/l10n/app_ar.arb');

  final enMap = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
  final arMap = jsonDecode(arFile.readAsStringSync()) as Map<String, dynamic>;

  void add(String key, String enVal, String arVal) {
    if (!enMap.containsKey(key)) enMap[key] = enVal;
    if (!arMap.containsKey(key)) arMap[key] = arVal;
  }

  // Plan Card
  add('planFullQuran', 'Full Quran', 'القرآن كاملاً');
  add('planTodaysPlan', 'Today\'s Plan', 'خطة اليوم');
  add('planExtraSession', 'Extra Session #{count}', 'جلسة إضافية #{count}');
  add('planSabaqNew', 'Sabaq · New', 'سبق · جديد');
  add('planSabqiReview', 'Sabqi · Review', 'سبقي · مراجعة');
  add('planManzilRevision', 'Manzil · Revision', 'منزل · مراجعة كبرى');
  add('planNoReviewYet', 'No review yet', 'لا توجد مراجعة بعد');
  add('planNotStartedYet', 'Not started yet', 'لم تبدأ بعد');
  add('planPageLines', 'Page {page} · Lines {start}–{end}', 'صفحة {page} · الأسطر {start}–{end}');
  add('planPageFromVerse', 'Page {page} · from verse {verse}', 'صفحة {page} · من الآية {verse}');
  add('planPagesCount', '{count} pages', '{count} صفحات');
  add('planPagesList', 'Pages {pages}', 'الصفحات {pages}');
  add('planPagesListMore', 'Pages {pages}… (+{more})', 'الصفحات {pages}… (+{more})');
  add('planJuzPages', 'Juz {juz} · {count} pages', 'الجزء {juz} · {count} صفحات');
  add('planEstimatedTotal', '~{minutes} min total', '~{minutes} دقيقة تقريباً');
  add('planTimeNew', '{minutes}m new', '{minutes}د جديد');
  add('planTimeReview', '{minutes}m review', '{minutes}د مراجعة');
  add('planTimeRevision', '{minutes}m revision', '{minutes}د تلاوة');
  add('planFlashcardsDue', '{count} flashcards due', '{count} بطاقات مستحقة');
  add('planSessionSteps', 'Session steps', 'خطوات الجلسة');
  add('planStartSession', 'Start Session', 'بدء الجلسة');
  add('planCompleted', 'Completed ✨', 'مكتملة ✨');
  add('planWhyThisPlan', 'Why this plan?', 'لماذا هذه الخطة؟');

  // Pre-Session
  add('preSessionDoneOffline', 'Done any offline?', 'هل أنجزت شيئاً خارج التطبيق؟');
  add('preSessionCheckPhases', 'Check phases you\'ve already completed to skip them', 'حدد المراحل التي أكملتها مسبقاً لتخطيها');
  add('preSessionMarkDone', 'Mark Session as Done', 'تحديد الجلسة كمكتملة');

  // Session
  add('sessionHowDidItGo', 'How did it go?', 'كيف كان أداؤك؟');
  add('sessionRatePerformance', 'Rate your {phase} performance', 'قيّم أداءك في {phase}');
  add('sessionAssessmentStrong', 'Strong', 'ممتاز');
  add('sessionAssessmentStrongDesc', 'I nailed it — confident', 'أتقنته — واثق جداً');
  add('sessionAssessmentOkay', 'Okay', 'جيد');
  add('sessionAssessmentOkayDesc', 'Got through it, some mistakes', 'أكملته، مع بعض الأخطاء');
  add('sessionAssessmentNeedsWork', 'Needs Work', 'يحتاج تدريب');
  add('sessionAssessmentNeedsWorkDesc', 'I struggled — need more practice', 'واجهت صعوبة — أحتاج لمزيد من التدريب');

  // Coverage
  add('coverageHowMuch', 'How much did you cover?', 'ما المقدار الذي أنجزته؟');
  add('coveragePlanned', 'Planned: Page {page} · {lines}', 'المخطط: صفحة {page} · {lines}');
  add('coverageAllLines', 'All planned lines', 'جميع الأسطر المخططة');
  add('coverageAllLinesDesc', 'I completed page {page} ({lines})', 'أكملت الصفحة {page} ({lines})');
  add('coveragePartOfPage', 'Part of the page', 'جزء من الصفحة');
  add('coveragePartOfPageDesc', 'I\'ll specify which verses I covered', 'سأحدد الآيات التي أنجزتها');
  add('coverageMoreThanPlanned', 'More than planned', 'أكثر من المخطط');
  add('coverageMoreThanPlannedDesc', 'I covered extra pages!', 'أنجزت صفحات إضافية!');

  // Complete
  add('completeSessionComplete', 'Session Complete!', 'اكتملت الجلسة!');
  add('completeTimeSpent', 'Time spent', 'الوقت المستغرق');
  add('completeTotalReps', 'Total reps', 'إجمالي التكرار');
  add('completeTomorrowsPreview', 'Tomorrow\'s preview', 'معاينة الغد');
  add('completePracticeFlashcards', 'Practice {count} Flashcards', 'تدرب على {count} بطاقات');
  add('completeBackToDashboard', 'Back to Dashboard', 'العودة للرئيسية');

  // Overlay
  add('overlayNewMemorization', 'New Memorization', 'حفظ جديد');
  add('overlayReview', 'Review', 'مراجعة');
  add('overlayRevision', 'Revision', 'تلاوة');
  add('overlayPractice', 'Practice', 'تدريب');
  add('overlaySimilarVerses', 'This page has similar verses', 'هذه الصفحة تحتوي على آيات متشابهة');
  add('overlayFree', 'Free', 'حُر');
  add('overlayGuided', 'Guided', 'مُوجّه');
  add('overlayListen', 'Listen', 'استماع');
  add('overlayListenDesc', 'Listen to the page being recited. Focus on the melody and pronunciation', 'استمع للصفحة المقروءة. ركز على اللحن والنطق');
  add('overlayTarget', 'target × {count}', 'الهدف × {count}');
  add('overlaySkip', 'Skip', 'تخطي');
  add('overlayPrev', 'Prev', 'السابق');
  add('overlayNext', 'Next', 'التالي');
  add('overlayFinish', 'Finish', 'إنهاء');
  add('overlayDone', 'Done', 'تم');

  final encoder = JsonEncoder.withIndent('  ');
  enFile.writeAsStringSync(encoder.convert(enMap) + '\n');
  arFile.writeAsStringSync(encoder.convert(arMap) + '\n');

  print('Successfully added ${enMap.length} keys.');
}
