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
  'nuh': _nuhContent,
  'isa_maryam': _isaMaryamContent,
  'adam': _adamContent,
  'dawud_sulayman': _dawudSulaymanContent,
  'dhul_qarnayn': _dhulQarnaynContent,
  'khidr': _khidrContent,
  'luqman': _luqmanContent,
  'patience': _patienceContent,
  'akhirah': _akhirahContent,
  'tawhid': _tawhidContent,
  'justice': _justiceContent,
  'nature': _natureContent,
  'mercy': _mercyContent,
  'gratitude': _gratitudeContent,
  'parables': _parablesContent,
  'family': _familyContent,
  'dua': _duaContent,
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

const _nuhContent = TopicContent(
  topicId: 'nuh',
  narrative:
      'The story of Nuh (Noah) is the Quran\'s ultimate testament to endurance. For 950 years, he called his people to God, facing relentless mockery and rejection. The narrative is not just about a catastrophic flood; it is a profound study in unwavering resolve, the pain of a father losing a son to disbelief, and the reality that salvation is tied to faith, not lineage.\n\n'
      'Through Nuh, the Quran teaches that success is not measured by the number of followers, but by steadfastness in delivering the message. His ark remains a timeless symbol of divine refuge in a drowning world.',
  narrativeAr:
      'قصة نوح في القرآن هي الشهادة الأعظم على قوة التحمل. طوال 950 عاماً، دعا قومه إلى الله، مواجهاً سخرية ورفضاً لا هوادة فيهما. لا تقتصر القصة على طوفان مدمر فحسب؛ بل هي دراسة عميقة في العزيمة الراسخة، وألم أب يفقد ابنه بسبب الكفر، وحقيقة أن النجاة مرتبطة بالإيمان لا بالنسب.\n\n'
      'من خلال نوح، يعلمنا القرآن أن النجاح لا يُقاس بعدد الأتباع، بل بالثبات على تبليغ الرسالة. وتبقى سفينته رمزاً خالداً للملاذ الإلهي في عالم غارق.',
  sections: [
    TopicSection(
      surahId: 11, startVerse: 25, endVerse: 49,
      perspective: 'The construction of the ark, the mockery of the chiefs, and the heartbreaking dialogue between Nuh and his drowning son.',
      perspectiveAr: 'صناعة الفلك، وسخرية الملأ، والحوار المفجع بين نوح وابنه الغريق.',
      keyVerseKeys: ['11:37', '11:42', '11:43'],
    ),
    TopicSection(
      surahId: 54, startVerse: 9, endVerse: 16,
      perspective: 'A brief but intensely dramatic depiction of the floodgates of heaven opening and the earth bursting with springs.',
      perspectiveAr: 'تصوير درامي مكثف لفتح أبواب السماء وتفجير الأرض عيوناً.',
      keyVerseKeys: ['54:10', '54:11', '54:14'],
    ),
    TopicSection(
      surahId: 71, startVerse: 1, endVerse: 28,
      perspective: 'A deeply personal surah entirely dedicated to Nuh\'s exhaustive pleas to his people, night and day, in public and in private.',
      perspectiveAr: 'سورة شخصية عميقة مكرسة بالكامل لنداءات نوح المستميتة لقومه، ليلاً ونهاراً، سراً وجهاراً.',
      keyVerseKeys: ['71:5', '71:10'],
    ),
  ],
);

const _isaMaryamContent = TopicContent(
  topicId: 'isa_maryam',
  narrative:
      'The Quran elevates Maryam (Mary) to a position of unparalleled honor — she is the only woman mentioned by name in the Quran, chosen above all women of the worlds. The narrative beautifully traces her miraculous birth, her dedication to the sanctuary, and the divine annunciation of her son, Isa (Jesus).\n\n'
      'Isa is uniquely described as a Word from God and a Spirit from Him. His story focuses on his miraculous birth without a father, his profound miracles performed by God\'s permission, and his role as a messenger of pure monotheism, ultimately clarifying his humanity and divine mission.',
  narrativeAr:
      'يرفع القرآن مريم إلى مكانة شرف لا مثيل لها — فهي المرأة الوحيدة المذكورة باسمها في القرآن، والمصطفاة على نساء العالمين. يتتبع السرد بجمال ولادتها المعجزة، ونذرها للمحراب، والبشارة الإلهية بابنها عيسى.\n\n'
      'يُوصَف عيسى بشكل فريد بأنه كلمة من الله وروح منه. تركز قصته على ولادته المعجزة بلا أب، ومعجزاته العظيمة بإذن الله، ودوره كرسول للتوحيد الخالص، مما يوضح بشفافية بشريته ورسالته الإلهية.',
  sections: [
    TopicSection(
      surahId: 3, startVerse: 35, endVerse: 59,
      perspective: 'The dedication of Maryam\'s mother, Zakariyyah\'s guardianship, and the angelic annunciation of a miraculous son.',
      perspectiveAr: 'نذر أم مريم، وكفالة زكريا، وبشارة الملائكة بابن معجزة.',
      keyVerseKeys: ['3:37', '3:42', '3:45'],
    ),
    TopicSection(
      surahId: 5, startVerse: 110, endVerse: 118,
      perspective: 'A divine recounting of Isa\'s miracles — the clay bird, healing the blind — and his testimony of monotheism before God.',
      perspectiveAr: 'تذكير إلهي بمعجزات عيسى — طير الطين، وإبراء الأكمه — وشهادته بالتوحيد أمام الله.',
      keyVerseKeys: ['5:110', '5:116'],
    ),
    TopicSection(
      surahId: 19, startVerse: 16, endVerse: 34,
      perspective: 'The tender, emotional narrative of Maryam\'s isolation, the birth under the palm tree, and the baby speaking from the cradle.',
      perspectiveAr: 'السرد العاطفي الرقيق لعزلة مريم، والولادة تحت النخلة، وتكلم الرضيع في المهد.',
      keyVerseKeys: ['19:23', '19:30', '19:33'],
    ),
  ],
);

const _adamContent = TopicContent(
  topicId: 'adam',
  narrative:
      'The story of Adam and Iblis (Satan) is the origin story of humanity and the blueprint for the cosmic struggle between free will, arrogance, and repentance. When God announced the creation of a vicegerent on earth, Iblis refused to bow, blinded by racial supremacy ("I am better than him; You created me from fire and him from clay").\n\n'
      'Unlike Iblis, who blamed God for his misguidance, Adam and Hawa (Eve) took responsibility for their mistake in eating from the forbidden tree. Their immediate prayer for forgiveness establishes the defining characteristic of humanity: we fall, but we repent.',
  narrativeAr:
      'قصة آدم وإبليس هي قصة البداية للبشرية، والمخطط الأساسي للصراع الكوني بين الإرادة الحرة، والكبر، والتوبة. حين أعلن الله خلق خليفة في الأرض، أبى إبليس السجود، أعمته النزعة الفوقية ("أنا خير منه خلقتني من نار وخلقته من طين").\n\n'
      'على عكس إبليس الذي ألقى باللوم على الله في غوايته، تحمل آدم وحواء مسؤولية خطئهما في الأكل من الشجرة المحرمة. دعاؤهما الفوري بالمغفرة يؤسس السمة المميزة للبشرية: نحن نخطئ، لكننا نتوب.',
  sections: [
    TopicSection(
      surahId: 2, startVerse: 30, endVerse: 39,
      perspective: 'The announcement to the angels, the teaching of the names, and the first revelation of human potential.',
      perspectiveAr: 'الإعلان للملائكة، وتعليم الأسماء، والتجلي الأول للإمكانيات البشرية.',
      keyVerseKeys: ['2:30', '2:31', '2:34'],
    ),
    TopicSection(
      surahId: 7, startVerse: 11, endVerse: 25,
      perspective: 'Iblis\'s arrogant refusal, his vow to deceive humanity, the whisper in Paradise, and the first prayer of repentance.',
      perspectiveAr: 'رفض إبليس المتكبر، وتعهده بغواية البشرية، والوسوسة في الجنة، والدعاء الأول للتوبة.',
      keyVerseKeys: ['7:12', '7:20', '7:23'],
    ),
    TopicSection(
      surahId: 20, startVerse: 115, endVerse: 123,
      perspective: 'The focus on human forgetfulness and vulnerability, culminating in God\'s ultimate forgiveness and guidance.',
      perspectiveAr: 'التركيز على النسيان والضعف البشري، متوجاً بمغفرة الله التامة وهدايته.',
      keyVerseKeys: ['20:115', '20:120', '20:122'],
    ),
  ],
);

const _dawudSulaymanContent = TopicContent(
  topicId: 'dawud_sulayman',
  narrative:
      'The story of the prophets Dawud (David) and his son Sulayman (Solomon) represents the pinnacle of righteous worldly power. Unlike prophets who were marginalized or oppressed, they were given unmatched kingdoms — control over the wind, the jinn, the birds, and mountains that echoed their praises.\n\n'
      'Yet, the Quran highlights that this immense power never corrupted them. They remained deeply devoted servants who turned to God in repentance. Their story teaches that worldly success and spiritual excellence are not mutually exclusive, provided power is coupled with profound gratitude.',
  narrativeAr:
      'تمثل قصة النبيين داود وابنه سليمان عليهما السلام قمة السلطة الدنيوية الصالحة. على عكس الأنبياء الذين تعرضوا للتهميش أو الاضطهاد، أُوتيا مُلكاً لا يُضاهى — تسخير الرياح، والجن، والطير، والجبال التي تردد تسبيحهما.\n\n'
      'ومع ذلك، يُبرز القرآن أن هذه القوة الهائلة لم تفسدهما قط. بل ظلا عبدين أوابين خاضعين لله. قصتهما تُعلّم أن النجاح الدنيوي والسمو الروحي ليسا متناقضين، شريطة أن تقترن السلطة بشكر عميق.',
  sections: [
    TopicSection(
      surahId: 21, startVerse: 78, endVerse: 82,
      perspective: 'Their shared wisdom in judgment, and the subjugation of nature and jinn to their command.',
      perspectiveAr: 'حكمتهما المشتركة في القضاء، وتسخير الطبيعة والجن لأمرهما.',
      keyVerseKeys: ['21:79', '21:81'],
    ),
    TopicSection(
      surahId: 27, startVerse: 15, endVerse: 44,
      perspective: 'Sulayman\'s magnificent kingdom, his understanding of animal languages, and his diplomatic encounter with the Queen of Sheba.',
      perspectiveAr: 'مُلك سليمان العظيم، وفهمه للغات الحيوانات، ولقاؤه الدبلوماسي مع ملكة سبأ.',
      keyVerseKeys: ['27:15', '27:19', '27:40'],
    ),
    TopicSection(
      surahId: 38, startVerse: 17, endVerse: 40,
      perspective: 'Dawud\'s repentance, his beautiful recitation of the Psalms (Zabur), and Sulayman\'s legendary horses.',
      perspectiveAr: 'توبة داود، وترتيله الجميل للزبور، وخيل سليمان الصافنات الجياد.',
      keyVerseKeys: ['38:17', '38:24', '38:30'],
    ),
  ],
);

const _dhulQarnaynContent = TopicContent(
  topicId: 'dhul_qarnayn',
  narrative:
      'Dhul-Qarnayn ("The Two-Horned One") was a great and just ruler whose empire stretched from the far west where the sun sets in a murky spring, to the far east. The Quran presents him as the ideal archetype of a leader who uses his God-given authority and resources strictly for justice and the protection of the vulnerable.\n\n'
      'His final recorded journey involves helping a defenseless people build a massive iron wall to protect them from the destructive tribes of Ya\'juj and Ma\'juj (Gog and Magog), attributing his success entirely to the mercy of his Lord.',
  narrativeAr:
      'ذو القرنين كان حاكماً عظيماً وعادلاً امتدت إمبراطوريته من أقصى الغرب حيث تغرب الشمس في عين حمئة، إلى أقصى الشرق. يقدمه القرآن كنموذج مثالي للقائد الذي يستخدم سلطته وموارده التي وهبها الله من أجل العدالة وحماية المستضعفين حصراً.\n\n'
      'تتضمن رحلته الأخيرة المذكورة مساعدة قوم لا حول لهم على بناء سد حديدي ضخم لحمايتهم من قبائل يأجوج ومأجوج المدمرة، عازياً نجاحه بالكامل إلى رحمة ربه.',
  sections: [
    TopicSection(
      surahId: 18, startVerse: 83, endVerse: 98,
      perspective: 'The three great journeys to the edges of the earth, and the construction of the iron barrier.',
      perspectiveAr: 'الرحلات الثلاث العظيمة إلى أطراف الأرض، وبناء السد الحديدي.',
      keyVerseKeys: ['18:84', '18:86', '18:95', '18:98'],
    ),
  ],
);

const _khidrContent = TopicContent(
  topicId: 'khidr',
  narrative:
      'The story of Musa and the wise servant, commonly known as Al-Khidr, is one of the most mysterious and profound narratives in the Quran. When Musa believed he was the most knowledgeable of men, God directed him to a servant endowed with a special, divine mercy and hidden knowledge.\n\n'
      'Musa\'s journey with Al-Khidr is a powerful lesson in intellectual humility. It reveals that human perception is severely limited, and that behind seemingly tragic or inexplicable events — a damaged ship, a slain boy, a rebuilt wall — lies the perfect, encompassing wisdom and mercy of God\'s plan.',
  narrativeAr:
      'قصة موسى والعبد الصالح، المعروف بالخضر، هي واحدة من أعمق الروايات وأكثرها غموضاً في القرآن. حين ظن موسى أنه أعلم أهل الأرض، وجهه الله إلى عبد أُوتي رحمة خاصة وعلماً لدنياً.\n\n'
      'رحلة موسى مع الخضر درس بليغ في التواضع الفكري. فهي تكشف أن الإدراك البشري محدود للغاية، وأن وراء الأحداث التي تبدو مأساوية أو غير مفهومة — كسفينة تُخرق، وغلام يُقتل، وجدار يُبنى — تكمن حكمة الله ورحمته المحيطة بكل شيء.',
  sections: [
    TopicSection(
      surahId: 18, startVerse: 60, endVerse: 82,
      perspective: 'Musa\'s quest for knowledge, the three inexplicable events, and the unveiling of divine wisdom behind them.',
      perspectiveAr: 'سعي موسى لطلب العلم، والأحداث الثلاثة الغامضة، وكشف الحكمة الإلهية وراءها.',
      keyVerseKeys: ['18:65', '18:66', '18:82'],
    ),
  ],
);

const _luqmanContent = TopicContent(
  topicId: 'luqman',
  narrative:
      'Luqman was not a prophet, but a wise sage — traditionally identified as an African carpenter or shepherd — whose profound wisdom earned him a surah named in his honor. The Quran immortalizes the intimate advice he gave to his son.\n\n'
      'His counsel serves as a masterclass in Islamic parenting and character development. He seamlessly connects the ultimate truth of monotheism with practical, everyday ethics: establishing prayer, respecting parents, lowering one\'s voice, and walking upon the earth without arrogance.',
  narrativeAr:
      'لم يكن لقمان نبياً، بل حكيماً — تُشير الروايات إلى أنه كان نجاراً أو راعياً أفريقياً — نال بحكمته العميقة شرف تسمية سورة باسمه. يُخلّد القرآن نصيحته الحميمة لابنه.\n\n'
      'تُعد وصاياه درساً نموذجياً في التربية الإسلامية وبناء الشخصية. فهو يربط ببراعة بين الحقيقة المطلقة للتوحيد والأخلاق العملية اليومية: إقامة الصلاة، وبر الوالدين، وغض الصوت، والمشي على الأرض بلا خيلاء.',
  sections: [
    TopicSection(
      surahId: 31, startVerse: 12, endVerse: 19,
      perspective: 'The profound advice of a father to his son, blending theology with character and social manners.',
      perspectiveAr: 'النصيحة العميقة من أب لابنه، والتي تمزج بين العقيدة والأخلاق والآداب الاجتماعية.',
      keyVerseKeys: ['31:13', '31:17', '31:18'],
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

const _justiceContent = TopicContent(
  topicId: 'justice',
  narrative:
      'Justice (\'Adl) is not merely a legal concept in the Quran; it is the central pillar of a righteous society and a divine attribute. The Quranic standard for justice is uncompromisingly absolute: it demands fairness even if it goes against oneself, one\'s parents, or one\'s relatives.\n\n'
      'Furthermore, the Quran explicitly forbids letting hatred or enmity toward a group prevent one from acting justly. From personal interactions to global economics, the establishment of justice is presented as a primary reason for the revelation of divine scriptures.',
  narrativeAr:
      'العدل ليس مجرد مفهوم قانوني في القرآن؛ بل هو الركيزة الأساسية للمجتمع الصالح وصفة إلهية. معيار القرآن للعدل مطلق ولا يقبل المساومة: فهو يطالب بالإنصاف حتى لو كان على حساب النفس أو الوالدين أو الأقربين.\n\n'
      'علاوة على ذلك، ينهى القرآن صراحة عن السماح لكراهية أو عداوة قوم بأن تمنع المرء من العدل. من التفاعلات الشخصية إلى الاقتصاد العالمي، يُعرض إرساء العدل كسبب رئيسي لإنزال الكتب السماوية.',
  sections: [
    TopicSection(
      surahId: 4, startVerse: 135, endVerse: 135,
      perspective: 'The absolute standard — standing firmly for justice as witnesses to God, even against oneself.',
      perspectiveAr: 'المعيار المطلق — القوامة بالقسط شهداء لله، ولو على النفس.',
      keyVerseKeys: ['4:135'],
    ),
    TopicSection(
      surahId: 5, startVerse: 8, endVerse: 8,
      perspective: 'Justice beyond enmity — letting not hatred for a people lead to injustice.',
      perspectiveAr: 'العدل فوق العداوة — ألا يجرمنكم شنآن قوم على ألا تعدلوا.',
      keyVerseKeys: ['5:8'],
    ),
    TopicSection(
      surahId: 83, startVerse: 1, endVerse: 6,
      perspective: 'Economic justice — a severe warning to those who cheat in measure and weight.',
      perspectiveAr: 'العدالة الاقتصادية — وعيد شديد للمطففين الذين يغشون في المكيال والميزان.',
      keyVerseKeys: ['83:1', '83:2', '83:3'],
    ),
  ],
);

const _natureContent = TopicContent(
  topicId: 'nature',
  narrative:
      'The Quran frequently directs humanity\'s gaze toward the natural world — the rain reviving dead earth, the orbits of the stars, the complex behavior of bees — calling them "Signs" (Ayat). The universe is presented as an open book, meant to be read alongside the revealed text.\n\n'
      'This profound connection to nature is designed to awaken intellectual curiosity and spiritual awe. By observing the flawless balance and intricate design of creation, the mind is naturally drawn to the perfection of the Creator.',
  narrativeAr:
      'يوجه القرآن أنظار البشرية مراراً وتكراراً نحو العالم الطبيعي — المطر الذي يحيي الأرض الميتة، ومدارات النجوم، والسلوك المعقد للنحل — واصفاً إياها بـ "الآيات". يُعرض الكون ككتاب مفتوح يُقرأ جنباً إلى جنب مع النص الموحى به.\n\n'
      'صُمم هذا الارتباط العميق بالطبيعة لإيقاظ الفضول الفكري والرهبة الروحية. فمن خلال تأمل التوازن الخالي من العيوب والتصميم الدقيق للخلق، ينجذب العقل بشكل طبيعي إلى كمال الخالق.',
  sections: [
    TopicSection(
      surahId: 16, startVerse: 65, endVerse: 69,
      perspective: 'The miraculous provisions in nature — rain, livestock milk, and the remarkable inspiration of the honey bee.',
      perspectiveAr: 'النعم المعجزة في الطبيعة — المطر، ولبن الأنعام، والإلهام العجيب لنحل العسل.',
      keyVerseKeys: ['16:66', '16:68', '16:69'],
    ),
    TopicSection(
      surahId: 30, startVerse: 20, endVerse: 25,
      perspective: 'The diversity of human languages and colors, lightning, and rain as signs for those who reflect.',
      perspectiveAr: 'اختلاف الألسنة والألوان، والبرق، والمطر كآيات لقوم يتفكرون.',
      keyVerseKeys: ['30:22', '30:24'],
    ),
    TopicSection(
      surahId: 55, startVerse: 1, endVerse: 20,
      perspective: 'A rhythmic celebration of the cosmos — the sun, the moon, the trees, and the meeting of the two seas.',
      perspectiveAr: 'احتفاء إيقاعي بالكون — الشمس، والقمر، والشجر، ومرج البحرين.',
      keyVerseKeys: ['55:5', '55:6', '55:19', '55:20'],
    ),
  ],
);

const _mercyContent = TopicContent(
  topicId: 'mercy',
  narrative:
      'God\'s mercy (Rahmah) is the most pervasive divine attribute in the Quran, encompassing all things. Every surah, save one, begins with the invocation of His boundless mercy. The Quran consistently reassures believers that the door to forgiveness is never closed, no matter the magnitude of the sin.\n\n'
      'Despairing of God\'s mercy is presented as a grave error, characteristic of those who do not truly know Him. His mercy outstrips His wrath, offering hope, comfort, and a path back to the Light at every moment.',
  narrativeAr:
      'رحمة الله هي الصفة الإلهية الأكثر شمولاً في القرآن، وسعت كل شيء. تبدأ كل سورة، باستثناء واحدة، باستدعاء رحمته الواسعة. ويطمئن القرآن المؤمنين باستمرار أن باب المغفرة لا يُغلق أبداً، مهما عظم الذنب.\n\n'
      'يُعرض اليأس من رحمة الله كخطأ فادح، من سمات الذين لا يعرفونه حق المعرفة. فسبقت رحمته غضبه، لتقدم الأمل، والعزاء، وطريقاً للعودة إلى النور في كل لحظة.',
  sections: [
    TopicSection(
      surahId: 39, startVerse: 53, endVerse: 55,
      perspective: 'The ultimate verse of hope — a direct call not to despair, for God forgives all sins.',
      perspectiveAr: 'آية الأمل العظمى — نداء مباشر بعدم اليأس، فالله يغفر الذنوب جميعاً.',
      keyVerseKeys: ['39:53'],
    ),
    TopicSection(
      surahId: 55, startVerse: 1, endVerse: 4,
      perspective: 'The Most Merciful is the one who taught the Quran and created humanity.',
      perspectiveAr: 'الرحمن هو الذي علّم القرآن وخلق الإنسان.',
      keyVerseKeys: ['55:1', '55:2', '55:3'],
    ),
    TopicSection(
      surahId: 93, startVerse: 1, endVerse: 11,
      perspective: 'A deeply comforting reassurance to the Prophet ﷺ during a time of silence and doubt.',
      perspectiveAr: 'طمأنة عميقة ومريحة للنبي ﷺ في وقت انقطاع الوحي والشك.',
      keyVerseKeys: ['93:3', '93:5'],
    ),
  ],
);

const _gratitudeContent = TopicContent(
  topicId: 'gratitude',
  narrative:
      'In the Quran, gratitude (Shukr) is much more than a fleeting feeling of thankfulness — it is a conscious worldview and the ultimate purpose of human creation. The opposite of gratitude is not merely ungratefulness, but Kufr (concealing the truth/disbelief).\n\n'
      'The Quran establishes a universal spiritual law: "If you are grateful, I will surely increase you." Recognizing God\'s favors, which are too numerous to count, is the foundation of a contented heart and a life of worship.',
  narrativeAr:
      'في القرآن، الشكر ليس مجرد شعور عابر بالامتنان — بل هو رؤية واعية للعالم والغاية القصوى من خلق الإنسان. ونقيض الشكر ليس مجرد الجحود، بل هو الكفر (تغطية الحق وإنكاره).\n\n'
      'يؤسس القرآن قانوناً روحياً عالمياً: "لئن شكرتم لأزيدنكم." إن إدراك نعم الله، التي لا تُعد ولا تُحصى، هو أساس القلب المطمئن وحياة العبادة.',
  sections: [
    TopicSection(
      surahId: 14, startVerse: 5, endVerse: 8,
      perspective: 'The divine promise — gratitude guarantees an increase in blessings, while ingratitude leads to severe consequences.',
      perspectiveAr: 'الوعد الإلهي — الشكر يضمن الزيادة في النعم، والجحود يؤدي إلى عواقب وخيمة.',
      keyVerseKeys: ['14:7'],
    ),
    TopicSection(
      surahId: 16, startVerse: 10, endVerse: 18,
      perspective: 'Known as the Surah of Blessings. A profound reminder that humanity could never fully count the favors of God.',
      perspectiveAr: 'تُعرف بسورة النعم. تذكير بليغ بأن البشرية لن تستطيع أبداً إحصاء نعم الله.',
      keyVerseKeys: ['16:14', '16:18'],
    ),
    TopicSection(
      surahId: 55, startVerse: 1, endVerse: 30,
      perspective: 'The powerful, rhythmic refrain demanding acknowledgment: "So which of the favors of your Lord will you deny?"',
      perspectiveAr: 'اللازمة الإيقاعية القوية التي تطالب بالاعتراف: "فبأي آلاء ربكما تكذبان؟"',
      keyVerseKeys: ['55:13'],
    ),
  ],
);

const _parablesContent = TopicContent(
  topicId: 'parables',
  narrative:
      'The Quran frequently uses parables (Amthal) to make profound, abstract spiritual truths accessible to the human mind. Through striking imagery drawn from the natural world and everyday life, the Quran bridges the gap between the seen and the unseen.\n\n'
      'A spider\'s fragile web exposes the weakness of false idols. A good word is likened to a deeply rooted tree yielding constant fruit. And in its most breathtaking parable, divine guidance is compared to a brilliant lamp within a niche, shining with the light of heavens and earth.',
  narrativeAr:
      'كثيراً ما يستخدم القرآن الأمثال لتبسيط الحقائق الروحية العميقة والمجردة للعقل البشري. من خلال صور معبرة مستوحاة من العالم الطبيعي والحياة اليومية، يجسّر القرآن الفجوة بين عالم الشهادة وعالم الغيب.\n\n'
      'فبيت العنكبوت الهش يكشف ضعف الأوثان الباطلة. والكلمة الطيبة تُشبه بشجرة راسخة الجذور تؤتي ثمارها دائماً. وفي أروع أمثاله، يُشبه الهدى الإلهي بمصباح ساطع في مشكاة، يضيء بنور السماوات والأرض.',
  sections: [
    TopicSection(
      surahId: 14, startVerse: 24, endVerse: 27,
      perspective: 'The parable of the good word as a strong tree, and the evil word as an uprooted, unstable plant.',
      perspectiveAr: 'مثل الكلمة الطيبة كشجرة ثابتة، والكلمة الخبيثة كنبتة مجتثة غير مستقرة.',
      keyVerseKeys: ['14:24', '14:25', '14:26'],
    ),
    TopicSection(
      surahId: 24, startVerse: 35, endVerse: 35,
      perspective: 'The Verse of Light (Ayat an-Nur) — a mesmerizing, multi-layered metaphor for God\'s light in the believer\'s heart.',
      perspectiveAr: 'آية النور — استعارة ساحرة ومتعددة الطبقات لنور الله في قلب المؤمن.',
      keyVerseKeys: ['24:35'],
    ),
    TopicSection(
      surahId: 29, startVerse: 41, endVerse: 43,
      perspective: 'The spider\'s web — exposing the ultimate fragility of relying on protectors other than God.',
      perspectiveAr: 'بيت العنكبوت — كشف الهشاشة المطلقة للاعتماد على أولياء من دون الله.',
      keyVerseKeys: ['29:41', '29:43'],
    ),
  ],
);

const _familyContent = TopicContent(
  topicId: 'family',
  narrative:
      'The Quran establishes the family unit as the foundational building block of human society. It does not leave family dynamics to custom alone; rather, it provides a comprehensive framework of rights, responsibilities, and profound ethical guidelines.\n\n'
      'From the sacred bond of marriage described as "tranquility, affection, and mercy," to the absolute obligation of honoring parents in their old age, the Quran weaves legal rulings with moral imperatives, demanding justice and kindness (Ihsan) behind closed doors.',
  narrativeAr:
      'يؤسس القرآن وحدة الأسرة كحجر الزاوية للمجتمع البشري. ولا يترك ديناميكيات الأسرة للعرف وحده؛ بل يقدم إطاراً شاملاً من الحقوق، والواجبات، والمبادئ الأخلاقية العميقة.\n\n'
      'من الرابط المقدس للزواج الموصوف بأنه "سكن ومودة ورحمة"، إلى الفريضة المطلقة ببر الوالدين في كبرهما، يدمج القرآن الأحكام الشرعية بالضرورات الأخلاقية، مطالباً بالعدل والإحسان خلف الأبواب المغلقة.',
  sections: [
    TopicSection(
      surahId: 4, startVerse: 1, endVerse: 36,
      perspective: 'The establishment of women\'s rights, the protection of orphans, and the command to treat parents and relatives with excellence.',
      perspectiveAr: 'إقرار حقوق النساء، وحماية اليتامى، والأمر بالإحسان إلى الوالدين والأقربين.',
      keyVerseKeys: ['4:1', '4:36'],
    ),
    TopicSection(
      surahId: 24, startVerse: 27, endVerse: 34,
      perspective: 'The etiquette of entering homes, preserving modesty, and protecting the honor and privacy of families.',
      perspectiveAr: 'آداب دخول البيوت، والحفاظ على العفة، وحماية أعراض وخصوصية العائلات.',
      keyVerseKeys: ['24:27', '24:30'],
    ),
    TopicSection(
      surahId: 49, startVerse: 10, endVerse: 13,
      perspective: 'The brotherhood of believers, and the prohibition of suspicion, backbiting, and racism that tear communities apart.',
      perspectiveAr: 'أخوة المؤمنين، والنهي عن سوء الظن والغيبة والعنصرية التي تمزق المجتمعات.',
      keyVerseKeys: ['49:10', '49:12', '49:13'],
    ),
  ],
);

const _duaContent = TopicContent(
  topicId: 'dua',
  narrative:
      'Du\'a (supplication) is described by the Prophet ﷺ as the essence of worship. The Quran is filled with the deeply personal prayers of prophets, angels, and righteous believers, teaching humanity not just that God answers, but *how* to ask.\n\n'
      'The Quran assures us of God\'s immediate proximity — He is closer than our jugular vein. When a servant calls upon Him, there are no intermediaries. "Call upon Me; I will respond to you" is both a divine command and an absolute promise.',
  narrativeAr:
      'وصف النبي ﷺ الدعاء بأنه مخ العبادة. يزخر القرآن بالأدعية الشخصية العميقة للأنبياء والملائكة والمؤمنين الصالحين، ليعلّم البشرية ليس فقط أن الله يستجيب، بل *كيف* تسأل.\n\n'
      'يطمئننا القرآن بقرب الله المباشر — فهو أقرب إلينا من حبل الوريد. حين يدعوه العبد، لا توجد وساطات. "ادعوني أستجب لكم" هو أمر إلهي ووعد قاطع في آن واحد.',
  sections: [
    TopicSection(
      surahId: 2, startVerse: 186, endVerse: 186,
      perspective: 'The ultimate assurance — God is near, and He answers the caller directly without any intermediary.',
      perspectiveAr: 'الطمأنينة المطلقة — الله قريب، ويجيب الداعي مباشرة بلا واسطة.',
      keyVerseKeys: ['2:186'],
    ),
    TopicSection(
      surahId: 25, startVerse: 63, endVerse: 77,
      perspective: 'The qualities of the "Servants of the Most Merciful" and the beautiful prayers they make for their families and salvation.',
      perspectiveAr: 'صفات "عباد الرحمن" والأدعية الجميلة التي يرفعونها من أجل عائلاتهم ونجاتهم.',
      keyVerseKeys: ['25:65', '25:74'],
    ),
    TopicSection(
      surahId: 40, startVerse: 60, endVerse: 60,
      perspective: 'The divine command to invoke Him, coupled with the absolute promise of His response.',
      perspectiveAr: 'الأمر الإلهي بالدعاء، مقترناً بالوعد القاطع بالاستجابة.',
      keyVerseKeys: ['40:60'],
    ),
  ],
);
