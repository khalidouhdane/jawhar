// Curated topic content for the Understand tab's TopicDetailScreen.
//
// Each TopicContent provides a narrative overview and per-surah sections
// with verse ranges, perspectives, and key verses for deep exploration.
// All content is bilingual (EN/AR).

import 'package:quran_app/data/surah_metadata.dart';

/// Rich curated content for a Quranic topic.
class TopicContent {
  final String topicId;
  final String narrative;
  final String narrativeAr;
  final List<TopicSection> sections;

  const TopicContent({
    required this.topicId,
    required this.narrative,
    required this.narrativeAr,
    required this.sections,
  });
}

/// A single surah's contribution to a topic.
class TopicSection {
  final int surahId;
  final int startVerse;
  final int endVerse;
  final String perspective;
  final String perspectiveAr;
  final List<String> keyVerseKeys;

  const TopicSection({
    required this.surahId,
    required this.startVerse,
    required this.endVerse,
    required this.perspective,
    required this.perspectiveAr,
    required this.keyVerseKeys,
  });

  /// Mushaf start page for this section's surah.
  int get startPage => surahStartPages[surahId];
}

/// Lookup: topicId → TopicContent. Returns null for uncurated topics.
const Map<String, TopicContent> topicContentRegistry = {
  'musa': _musaContent,
  'yusuf': _yusufContent,
  'ibrahim': _ibrahimContent,
  'patience': _patienceContent,
  'akhirah': _akhirahContent,
  'tawhid': _tawhidContent,
};

// ── Stories ──

const _musaContent = TopicContent(
  topicId: 'musa',
  narrative:
      'The story of Musa (Moses) is the most frequently told narrative in the Quran, appearing in over thirty surahs. Each retelling emphasizes a different facet: his birth and rescue by Pharaoh\'s household, his flight to Midian, the divine call at the burning bush, the confrontation with Pharaoh, the plagues, the exodus through the parted sea, and the challenges of leading Bani Isra\'il afterward.\n\n'
      'This repetition is deliberate. The Quran revisits Musa\'s story not to repeat itself, but to draw out lessons relevant to each surah\'s context — sometimes focusing on courage in the face of tyranny, sometimes on patience with an ungrateful community, and sometimes on the intimacy of divine conversation.',
  narrativeAr:
      'قصة موسى عليه السلام هي الأكثر تكراراً في القرآن الكريم، حيث وردت في أكثر من ثلاثين سورة. كل رواية تُبرز جانباً مختلفاً: ولادته وإنقاذه على يد آل فرعون، هجرته إلى مدين، النداء الإلهي عند الشجرة، المواجهة مع فرعون، الآيات والمعجزات، الخروج عبر البحر، وتحديات قيادة بني إسرائيل.\n\n'
      'هذا التكرار مقصود. فالقرآن يعيد زيارة قصة موسى لا للتكرار، بل لاستخلاص دروس تناسب سياق كل سورة — تارةً يركز على الشجاعة في مواجهة الطغيان، وتارةً على الصبر مع قوم جاحدين، وأحياناً على حميمية المناجاة الإلهية.',
  sections: [
    TopicSection(
      surahId: 2, startVerse: 49, endVerse: 73,
      perspective: 'Bani Isra\'il\'s deliverance and the lessons they failed to learn — ingratitude after salvation.',
      perspectiveAr: 'إنقاذ بني إسرائيل والدروس التي لم يتعلموها — الجحود بعد النجاة.',
      keyVerseKeys: ['2:60', '2:67'],
    ),
    TopicSection(
      surahId: 7, startVerse: 103, endVerse: 162,
      perspective: 'The most detailed account of the confrontation with Pharaoh — the signs, the sorcerers\' conversion, and Pharaoh\'s arrogance.',
      perspectiveAr: 'أكثر الروايات تفصيلاً للمواجهة مع فرعون — الآيات، إيمان السحرة، وعناد فرعون.',
      keyVerseKeys: ['7:116', '7:120', '7:143'],
    ),
    TopicSection(
      surahId: 20, startVerse: 9, endVerse: 98,
      perspective: 'The intimate divine call — Musa\'s fear, his staff, his mission. The most personal retelling.',
      perspectiveAr: 'النداء الإلهي الحميم — خوف موسى، عصاه، رسالته. أكثر الروايات شخصية.',
      keyVerseKeys: ['20:12', '20:25', '20:39'],
    ),
    TopicSection(
      surahId: 28, startVerse: 3, endVerse: 42,
      perspective: 'The origin story — Musa\'s birth, his mother\'s faith, growing up in Pharaoh\'s palace, the accidental killing, and flight to Midian.',
      perspectiveAr: 'قصة البداية — ولادة موسى، إيمان أمه، نشأته في قصر فرعون، القتل الخطأ، والهجرة إلى مدين.',
      keyVerseKeys: ['28:7', '28:15', '28:30'],
    ),
  ],
);

const _yusufContent = TopicContent(
  topicId: 'yusuf',
  narrative:
      'Surah Yusuf is unique in the Quran — it is the only surah that tells a complete story from beginning to end in a single, continuous narrative. Allah calls it "the best of stories" (ahsan al-qasas). The story follows Yusuf from his childhood dream, through betrayal by his brothers, slavery in Egypt, imprisonment, rise to power, and the dramatic reunion with his family.\n\n'
      'Every twist in Yusuf\'s life carries a profound lesson: patience through injustice, maintaining integrity under temptation, the wisdom of forgiveness, and the certainty that God\'s plan unfolds perfectly — even when it seems cruel.',
  narrativeAr:
      'سورة يوسف فريدة في القرآن — فهي السورة الوحيدة التي تروي قصة كاملة من البداية إلى النهاية في سرد متصل. سمّاها الله "أحسن القصص". تتبع القصة يوسف من رؤياه في طفولته، مروراً بخيانة إخوته، والعبودية في مصر، والسجن، والصعود إلى السلطة، واللقاء المؤثر مع عائلته.\n\n'
      'كل منعطف في حياة يوسف يحمل درساً عميقاً: الصبر على الظلم، والحفاظ على النزاهة أمام الإغراء، وحكمة المغفرة، واليقين بأن تدبير الله يتحقق بإتقان — حتى حين يبدو قاسياً.',
  sections: [
    TopicSection(
      surahId: 12, startVerse: 4, endVerse: 18,
      perspective: 'The dream and the brothers\' plot — jealousy tears a family apart.',
      perspectiveAr: 'الرؤيا ومؤامرة الإخوة — الحسد يمزق أسرة.',
      keyVerseKeys: ['12:4', '12:18'],
    ),
    TopicSection(
      surahId: 12, startVerse: 21, endVerse: 34,
      perspective: 'In Egypt — the trial of temptation and Yusuf\'s unwavering integrity.',
      perspectiveAr: 'في مصر — امتحان الإغراء واستقامة يوسف الراسخة.',
      keyVerseKeys: ['12:23', '12:33'],
    ),
    TopicSection(
      surahId: 12, startVerse: 35, endVerse: 57,
      perspective: 'Prison to palace — patience rewarded, the king\'s dream interpreted.',
      perspectiveAr: 'من السجن إلى القصر — الصبر يُثمر، وتأويل رؤيا الملك.',
      keyVerseKeys: ['12:40', '12:55'],
    ),
    TopicSection(
      surahId: 12, startVerse: 58, endVerse: 101,
      perspective: 'The reunion — forgiveness triumphs over revenge, and the childhood dream is fulfilled.',
      perspectiveAr: 'اللقاء — المغفرة تنتصر على الانتقام، وتتحقق رؤيا الطفولة.',
      keyVerseKeys: ['12:64', '12:90', '12:100'],
    ),
  ],
);

const _ibrahimContent = TopicContent(
  topicId: 'ibrahim',
  narrative:
      'Ibrahim (Abraham) holds a unique place in the Quran as the patriarch of monotheism, honored with the title Khalil Allah — the intimate friend of God. His story spans the journey from questioning his father\'s idolatry, to the trial by fire, to building the Ka\'bah with his son Isma\'il, to the ultimate test of sacrificing his beloved child.\n\n'
      'The Quran presents Ibrahim as the model of submission (islam in its purest sense) — a man who, when told to submit, said "I have submitted to the Lord of the worlds." His legacy connects the three Abrahamic faiths.',
  narrativeAr:
      'يحتل إبراهيم عليه السلام مكانة فريدة في القرآن بوصفه أبا التوحيد، مُكرَّماً بلقب خليل الله. تمتد قصته من مساءلة أبيه عن عبادة الأصنام، إلى امتحان النار، إلى بناء الكعبة مع ابنه إسماعيل، إلى الامتحان الأعظم بذبح ولده الحبيب.\n\n'
      'يقدم القرآن إبراهيم نموذجاً للإسلام بأنقى معانيه — رجل حين قيل له أَسلِم قال: "أسلمت لرب العالمين". إرثه يربط بين الأديان الإبراهيمية الثلاثة.',
  sections: [
    TopicSection(
      surahId: 2, startVerse: 124, endVerse: 141,
      perspective: 'Building the Ka\'bah with Isma\'il and the foundational prayer for Makkah.',
      perspectiveAr: 'بناء الكعبة مع إسماعيل والدعاء التأسيسي لمكة.',
      keyVerseKeys: ['2:127', '2:131'],
    ),
    TopicSection(
      surahId: 6, startVerse: 74, endVerse: 83,
      perspective: 'Ibrahim\'s intellectual journey — reasoning through the stars, moon, and sun to arrive at pure monotheism.',
      perspectiveAr: 'رحلة إبراهيم الفكرية — التأمل في النجوم والقمر والشمس وصولاً إلى التوحيد الخالص.',
      keyVerseKeys: ['6:76', '6:79'],
    ),
    TopicSection(
      surahId: 21, startVerse: 51, endVerse: 73,
      perspective: 'Smashing the idols and the trial by fire — "We said: O fire, be cool and safe for Ibrahim."',
      perspectiveAr: 'تحطيم الأصنام والامتحان بالنار — "قلنا يا نار كوني برداً وسلاماً على إبراهيم."',
      keyVerseKeys: ['21:58', '21:69'],
    ),
    TopicSection(
      surahId: 37, startVerse: 83, endVerse: 113,
      perspective: 'The ultimate test — the dream of sacrificing Isma\'il, and the ransom from God.',
      perspectiveAr: 'الامتحان الأعظم — رؤيا ذبح إسماعيل، والفداء من الله.',
      keyVerseKeys: ['37:102', '37:107'],
    ),
  ],
);

// ── Themes ──

const _patienceContent = TopicContent(
  topicId: 'patience',
  narrative:
      'Patience (sabr) in the Quran is not passive resignation — it is an active, conscious choice to trust God\'s wisdom when circumstances are painful. The Quran pairs patience with prayer, with gratitude, and with certainty that relief follows hardship.\n\n'
      'From the promise that "with hardship comes ease" repeated twice in Surah Ash-Sharh, to Yaqub\'s "beautiful patience" when told of Yusuf\'s loss, the Quran paints patience as strength — not weakness.',
  narrativeAr:
      'الصبر في القرآن ليس استسلاماً سلبياً — بل هو اختيار واعٍ للثقة بحكمة الله حين تكون الظروف مؤلمة. يقرن القرآن الصبر بالصلاة، وبالشكر، وباليقين أن الفرج يعقب الشدة.\n\n'
      'من الوعد بأن "مع العسر يسراً" المكرر في سورة الشرح، إلى "صبر جميل" يعقوب حين أُخبر بفقد يوسف، يرسم القرآن الصبر قوةً لا ضعفاً.',
  sections: [
    TopicSection(
      surahId: 2, startVerse: 153, endVerse: 157,
      perspective: 'The foundational commandment — "Seek help through patience and prayer." God is with the patient.',
      perspectiveAr: 'الأمر التأسيسي — "استعينوا بالصبر والصلاة." إن الله مع الصابرين.',
      keyVerseKeys: ['2:153', '2:155', '2:157'],
    ),
    TopicSection(
      surahId: 12, startVerse: 18, endVerse: 90,
      perspective: 'Yaqub\'s "beautiful patience" and Yusuf\'s endurance through betrayal, slavery, and prison.',
      perspectiveAr: '"فصبر جميل" ليعقوب وصبر يوسف على الخيانة والعبودية والسجن.',
      keyVerseKeys: ['12:18', '12:83', '12:90'],
    ),
    TopicSection(
      surahId: 93, startVerse: 1, endVerse: 11,
      perspective: 'God\'s reassurance to the Prophet ﷺ — "Your Lord has not abandoned you." A surah of comfort after darkness.',
      perspectiveAr: 'طمأنة الله لنبيه ﷺ — "ما ودعك ربك وما قلى." سورة عزاء بعد الظلمة.',
      keyVerseKeys: ['93:3', '93:5'],
    ),
    TopicSection(
      surahId: 94, startVerse: 1, endVerse: 8,
      perspective: '"With hardship comes ease" — twice repeated for emphasis. The promise that relief is certain.',
      perspectiveAr: '"إن مع العسر يسراً" — مكررة مرتين للتأكيد. وعد بأن الفرج أكيد.',
      keyVerseKeys: ['94:5', '94:6'],
    ),
  ],
);

const _akhirahContent = TopicContent(
  topicId: 'akhirah',
  narrative:
      'The Quran\'s depictions of the Day of Judgment and the afterlife are among its most vivid and powerful passages. Using cosmic imagery — the sun folded, the stars scattered, the mountains crumbled — it paints a scene of absolute accountability where every soul faces what it earned.\n\n'
      'These passages serve a dual purpose: they remind the reader that this world is temporary, and they motivate righteous action through the contrast between Paradise and Hell. The short, rhythmic surahs of Juz Amma deliver these scenes with particular intensity.',
  narrativeAr:
      'تصوير القرآن ليوم القيامة والآخرة من أقوى مشاهده وأكثرها تأثيراً. بصور كونية — الشمس تُكوَّر، والنجوم تنكدر، والجبال تُسيَّر — يرسم مشهد الحساب المطلق حيث تواجه كل نفس ما كسبت.\n\n'
      'تخدم هذه المشاهد غرضاً مزدوجاً: تذكّر القارئ بأن الدنيا فانية، وتحفز على العمل الصالح من خلال التباين بين الجنة والنار. سور جزء عمّ القصيرة الإيقاعية تقدم هذه المشاهد بكثافة خاصة.',
  sections: [
    TopicSection(
      surahId: 56, startVerse: 1, endVerse: 96,
      perspective: 'The three groups of humanity — the forerunners, the people of the right, and the people of the left.',
      perspectiveAr: 'الأصناف الثلاثة — السابقون، وأصحاب اليمين، وأصحاب الشمال.',
      keyVerseKeys: ['56:1', '56:10', '56:57'],
    ),
    TopicSection(
      surahId: 75, startVerse: 1, endVerse: 40,
      perspective: 'The resurrection and the moment of reckoning — the soul knows exactly what it did.',
      perspectiveAr: 'القيامة ولحظة الحساب — النفس تعلم تماماً ما قدمت.',
      keyVerseKeys: ['75:1', '75:14', '75:22'],
    ),
    TopicSection(
      surahId: 81, startVerse: 1, endVerse: 14,
      perspective: 'Cosmic collapse — the sun folded, the stars fallen, the mountains vanished. Pure apocalyptic imagery.',
      perspectiveAr: 'الانهيار الكوني — الشمس كُوِّرت، النجوم انكدرت، الجبال سُيِّرت. صور أخروية خالصة.',
      keyVerseKeys: ['81:1', '81:7', '81:10'],
    ),
    TopicSection(
      surahId: 99, startVerse: 1, endVerse: 8,
      perspective: 'The earth reveals everything — "Whoever does an atom\'s weight of good will see it."',
      perspectiveAr: 'الأرض تكشف كل شيء — "فمن يعمل مثقال ذرة خيراً يره."',
      keyVerseKeys: ['99:1', '99:7', '99:8'],
    ),
  ],
);

const _tawhidContent = TopicContent(
  topicId: 'tawhid',
  narrative:
      'Monotheism (tawhid) is the central message of the Quran — the foundation upon which every other teaching rests. From the opening surah\'s declaration "You alone we worship, You alone we ask for help" to the closing affirmation of Surah Al-Ikhlas, the Quran returns again and again to the oneness, uniqueness, and absolute sovereignty of God.\n\n'
      'The Quran presents tawhid not as an abstract theological concept but as a living reality: God\'s signs are in every created thing, His names and attributes pervade every verse, and the ultimate purpose of human existence is to recognize and worship Him alone.',
  narrativeAr:
      'التوحيد هو الرسالة المحورية للقرآن — الأساس الذي يقوم عليه كل تعليم آخر. من إعلان الفاتحة "إياك نعبد وإياك نستعين" إلى تأكيد سورة الإخلاص الختامي، يعود القرآن مراراً إلى وحدانية الله وتفرده وسيادته المطلقة.\n\n'
      'يقدم القرآن التوحيد لا كمفهوم لاهوتي مجرد بل كحقيقة حية: آيات الله في كل مخلوق، وأسماؤه وصفاته تسري في كل آية، والغاية القصوى من الوجود البشري معرفته وعبادته وحده.',
  sections: [
    TopicSection(
      surahId: 1, startVerse: 1, endVerse: 7,
      perspective: 'The opening declaration — "You alone we worship, You alone we ask for help." The daily renewal of tawhid.',
      perspectiveAr: 'الإعلان الافتتاحي — "إياك نعبد وإياك نستعين." التجديد اليومي للتوحيد.',
      keyVerseKeys: ['1:1', '1:5'],
    ),
    TopicSection(
      surahId: 2, startVerse: 255, endVerse: 255,
      perspective: 'Ayat al-Kursi — the greatest verse in the Quran. A comprehensive portrait of God\'s attributes.',
      perspectiveAr: 'آية الكرسي — أعظم آية في القرآن. صورة شاملة لصفات الله.',
      keyVerseKeys: ['2:255'],
    ),
    TopicSection(
      surahId: 6, startVerse: 95, endVerse: 103,
      perspective: 'God\'s signs in creation — seeds, stars, water, and the declaration "No vision can grasp Him."',
      perspectiveAr: 'آيات الله في الخلق — البذور، النجوم، الماء، وإعلان "لا تدركه الأبصار."',
      keyVerseKeys: ['6:95', '6:101', '6:103'],
    ),
    TopicSection(
      surahId: 112, startVerse: 1, endVerse: 4,
      perspective: 'The purest declaration of tawhid — four verses that define God\'s absolute oneness.',
      perspectiveAr: 'أنقى إعلان للتوحيد — أربع آيات تعرّف وحدانية الله المطلقة.',
      keyVerseKeys: ['112:1', '112:2', '112:3'],
    ),
  ],
);
