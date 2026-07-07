import 'vocab_service.dart';

class FillBlankPrompt {
  const FillBlankPrompt({
    required this.item,
    required this.sentenceWithBlank,
    required this.sentenceWithAnswer,
    required this.showVisualHint,
  });

  final VocabItem item;
  final String sentenceWithBlank;
  final String sentenceWithAnswer;
  final bool showVisualHint;
}

class VocabFillBlankService {
  const VocabFillBlankService();

  static const blankToken = '_____';

  List<String> availableCategories({
    required List<VocabItem> items,
    required String difficulty,
    required int qaMode,
  }) {
    final categories = items.map((item) => item.category).toSet().toList()
      ..sort();

    return categories
        .where(
          (category) => promptsForCategory(
            items: items.where((item) => item.category == category).toList(),
            difficulty: difficulty,
            qaMode: qaMode,
          ).length >= qaMode,
        )
        .toList();
  }

  List<FillBlankPrompt> promptsForCategory({
    required List<VocabItem> items,
    required String difficulty,
    required int qaMode,
  }) {
    final level = _difficultyLevel(difficulty);
    final prompts = <FillBlankPrompt>[];

    for (final item in items) {
      final prompt = _promptForItem(item, level);
      if (prompt != null) {
        prompts.add(prompt);
      }
    }

    if (prompts.length < qaMode) {
      return const [];
    }

    return prompts;
  }

  FillBlankPrompt? _promptForItem(VocabItem item, int level) {
    final normalizedWord = _normalizeWord(item.word);
    final clueTemplates = _wordClues[normalizedWord];
    final selectedClue = _pickTemplate(clueTemplates, level, item.word);
    if (selectedClue != null) {
      return _buildPrompt(item, selectedClue);
    }

    if (!_isEligibleSingleWord(item.word)) {
      return null;
    }

    final canonicalCategory = _canonicalCategory(item.category);
    final categoryTemplates = _categoryTemplates[canonicalCategory];
    final selectedTemplate = _pickTemplate(categoryTemplates, level, item.word);
    if (selectedTemplate == null) {
      return null;
    }

    return _buildPrompt(item, selectedTemplate);
  }

  FillBlankPrompt _buildPrompt(VocabItem item, _PromptTemplate template) {
    final article = _articleFor(item.word);
    final sentenceWithBlank = template.text
        .replaceAll('{{article}}', article)
        .replaceAll('___', blankToken);
    final sentenceWithAnswer = template.text
        .replaceAll('{{article}}', article)
        .replaceAll('___', item.word);

    return FillBlankPrompt(
      item: item,
      sentenceWithBlank: sentenceWithBlank,
      sentenceWithAnswer: sentenceWithAnswer,
      showVisualHint: template.showVisualHint,
    );
  }

  _PromptTemplate? _pickTemplate(
    List<_PromptTemplate>? templates,
    int level,
    String seed,
  ) {
    if (templates == null || templates.isEmpty) return null;

    final eligible = templates
        .where((template) => template.minDifficulty <= level)
        .toList();
    if (eligible.isEmpty) return null;

    final index = seed.hashCode.abs() % eligible.length;
    return eligible[index];
  }

  String _canonicalCategory(String raw) {
    final normalized = _normalizeCategory(raw);
    for (final entry in _categoryAliases.entries) {
      if (entry.value.contains(normalized)) {
        return entry.key;
      }
    }
    return normalized;
  }

  bool _isEligibleSingleWord(String word) {
    final trimmed = word.trim();
    return trimmed.isNotEmpty && !trimmed.contains(RegExp(r'\s+'));
  }

  int _difficultyLevel(String difficulty) {
    switch (difficulty.trim().toLowerCase()) {
      case 'advanced':
        return 2;
      case 'intermediate':
        return 1;
      case 'beginner':
      default:
        return 0;
    }
  }

  String _normalizeWord(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  String _normalizeCategory(String value) => _normalizeWord(value);

  String _articleFor(String word) {
    final trimmed = word.trim().toLowerCase();
    if (trimmed.isEmpty) return 'a';
    return 'aeiou'.contains(trimmed[0]) ? 'an' : 'a';
  }
}

class _PromptTemplate {
  const _PromptTemplate(
    this.text, {
    this.minDifficulty = 0,
    this.showVisualHint = false,
  });

  final String text;
  final int minDifficulty;
  final bool showVisualHint;
}

const _categoryAliases = <String, Set<String>>{
  'basic_needs': {'basic_needs', 'needs'},
  'feelings': {'feelings', 'emotions', 'feelings_emotions'},
  'food_drinks': {'food_drinks', 'food_and_drinks', 'food', 'drinks'},
  'people': {'people', 'person'},
  'actions': {'actions', 'action'},
  'places': {'places', 'place'},
  'choices': {'yes_no_choices', 'yes_no', 'choices', 'choice'},
  'social': {'social_communication', 'social', 'communication'},
  'body': {'body_pain', 'body', 'pain'},
  'school': {'learning_school', 'learning', 'school'},
  'animals': {'animals', 'animal'},
};

const _categoryTemplates = <String, List<_PromptTemplate>>{
  'feelings': [
    _PromptTemplate('I feel ___.', showVisualHint: true),
    _PromptTemplate('Today I feel ___.', minDifficulty: 1, showVisualHint: true),
    _PromptTemplate(
      'Right now I feel ___.',
      minDifficulty: 2,
      showVisualHint: true,
    ),
  ],
  'actions': [
    _PromptTemplate('I can ___.', showVisualHint: true),
    _PromptTemplate('Time to ___.', minDifficulty: 1, showVisualHint: true),
    _PromptTemplate(
      'I am ready to ___.',
      minDifficulty: 2,
      showVisualHint: true,
    ),
  ],
};

const _wordClues = <String, List<_PromptTemplate>>{
  'eat': [
    _PromptTemplate('I do this when I have food. I ___.', showVisualHint: true),
  ],
  'drink': [
    _PromptTemplate(
      'I do this when I am thirsty. I ___.',
      showVisualHint: true,
    ),
  ],
  'toilet': [
    _PromptTemplate(
      'I go here when I need the bathroom. It is the ___.',
      showVisualHint: true,
    ),
  ],
  'sleep': [
    _PromptTemplate('I do this at bedtime. I ___.', showVisualHint: true),
  ],
  'help': [
    _PromptTemplate(
      'I ask for this when something is hard. I need ___.',
      showVisualHint: true,
    ),
  ],
  'more': [
    _PromptTemplate(
      'I say this when I want extra. I want ___.',
      showVisualHint: true,
    ),
  ],
  'stop': [
    _PromptTemplate(
      'I say this when I want it to end. Please ___.',
      showVisualHint: true,
    ),
  ],
  'finished': [
    _PromptTemplate('I say this when I am done. I am ___.'),
  ],
  'break': [
    _PromptTemplate(
      'I take this when I need to rest. I need a ___.',
      showVisualHint: true,
    ),
  ],
  'rice': [
    _PromptTemplate('I eat this in a bowl or on a plate. It is ___.'),
  ],
  'bread': [
    _PromptTemplate('I can make toast with this. It is ___.'),
  ],
  'noodles': [
    _PromptTemplate('These are long and I eat them from a bowl. They are ___.'),
  ],
  'chicken': [
    _PromptTemplate('This food is a kind of meat. It is ___.'),
    _PromptTemplate(
      'This farm animal lays eggs. It is a ___.',
      minDifficulty: 1,
      showVisualHint: true,
    ),
  ],
  'egg': [
    _PromptTemplate('I can crack this for breakfast. It is an ___.'),
  ],
  'apple': [
    _PromptTemplate('This fruit can be red or green. It is an ___.'),
  ],
  'banana': [
    _PromptTemplate('This fruit is yellow and curved. It is a ___.'),
  ],
  'biscuit': [
    _PromptTemplate('This is a small crunchy snack. It is a ___.'),
  ],
  'milk': [
    _PromptTemplate('This drink is white. It is ___.'),
  ],
  'water': [
    _PromptTemplate('This clear drink helps when I am thirsty. It is ___.'),
  ],
  'juice': [
    _PromptTemplate('This fruity drink is ___.'),
  ],
  'snack': [
    _PromptTemplate('A small thing to eat is a ___.'),
  ],
  'mama': [
    _PromptTemplate('I can call my mother ___.', showVisualHint: true),
  ],
  'papa': [
    _PromptTemplate('I can call my father ___.', showVisualHint: true),
  ],
  'teacher': [
    _PromptTemplate('This person helps me learn. It is my ___.'),
  ],
  'friend': [
    _PromptTemplate('This is someone I like to play with. A ___.'),
  ],
  'brother': [
    _PromptTemplate('A boy in my family can be my ___.'),
  ],
  'sister': [
    _PromptTemplate('A girl in my family can be my ___.'),
  ],
  'doctor': [
    _PromptTemplate('This person helps me when I am sick. A ___.'),
  ],
  'me': [
    _PromptTemplate('This word means myself. It is ___.', showVisualHint: true),
  ],
  'you': [
    _PromptTemplate('This word means the other person. It is ___.'),
  ],
  'home': [
    _PromptTemplate('This is where my family lives. It is ___.'),
  ],
  'school': [
    _PromptTemplate('This is where I go to learn. It is ___.'),
  ],
  'class': [
    _PromptTemplate('This is the room where I learn. It is my ___.'),
  ],
  'kitchen': [
    _PromptTemplate('This is where we cook food. It is the ___.'),
  ],
  'bedroom': [
    _PromptTemplate('This is the room where I sleep. It is the ___.'),
  ],
  'playground': [
    _PromptTemplate('This is where I can slide and swing. It is the ___.'),
  ],
  'clinic': [
    _PromptTemplate('I can see a doctor at the ___.'),
  ],
  'shop': [
    _PromptTemplate('This is where we buy things. It is the ___.'),
  ],
  'car': [
    _PromptTemplate('I can ride in this on the road. It is a ___.'),
  ],
  'yes': [
    _PromptTemplate('I say this when the answer is right. It is ___.'),
  ],
  'no': [
    _PromptTemplate('I say this when I do not want it. It is ___.'),
  ],
  'maybe': [
    _PromptTemplate('I say this when I am not sure. It is ___.'),
  ],
  'again': [
    _PromptTemplate('I say this when I want one more turn. It is ___.'),
  ],
  'different': [
    _PromptTemplate('I say this when I want another one. It is ___.'),
  ],
  'same': [
    _PromptTemplate('I say this when I want it just like before. It is ___.'),
  ],
  'choose': [
    _PromptTemplate('I do this when I pick one. I ___.', showVisualHint: true),
  ],
  'hello': [
    _PromptTemplate('I say this when I meet someone. It is ___.'),
  ],
  'goodbye': [
    _PromptTemplate('I say this when I leave. It is ___.'),
  ],
  'thank_you': [
    _PromptTemplate('I say this after someone helps me. It is ___.'),
  ],
  'sorry': [
    _PromptTemplate('I say this when I made a mistake. It is ___.'),
  ],
  'please': [
    _PromptTemplate('I say this to sound polite. It is ___.'),
  ],
  'head': [
    _PromptTemplate('I wear a hat on my ___.'),
  ],
  'stomach': [
    _PromptTemplate('Food goes into my ___.'),
  ],
  'hand': [
    _PromptTemplate('I hold things with my ___.'),
  ],
  'leg': [
    _PromptTemplate('I walk and kick with my ___.'),
  ],
  'mouth': [
    _PromptTemplate('I eat and talk with my ___.'),
  ],
  'ear': [
    _PromptTemplate('I hear with my ___.'),
  ],
  'eye': [
    _PromptTemplate('I see with my ___.'),
  ],
  'pain': [
    _PromptTemplate('When my body feels bad, I have ___.'),
  ],
  'book': [
    _PromptTemplate('I can read this at school. It is a ___.'),
  ],
  'pencil': [
    _PromptTemplate('I write or draw with this. It is a ___.'),
  ],
  'bag': [
    _PromptTemplate('I carry my school things in a ___.'),
  ],
  'chair': [
    _PromptTemplate('I sit on a ___.'),
  ],
  'table': [
    _PromptTemplate('I put my book on the ___.'),
  ],
  'question': [
    _PromptTemplate('I ask a ___.'),
  ],
  'answer': [
    _PromptTemplate('I give an ___.'),
  ],
  'correct': [
    _PromptTemplate('The right answer is ___.'),
  ],
  'wrong': [
    _PromptTemplate('The not-right answer is ___.'),
  ],
  'cat': [
    _PromptTemplate('This animal says meow. It is a ___.', showVisualHint: true),
  ],
  'dog': [
    _PromptTemplate('This animal says woof. It is a ___.', showVisualHint: true),
  ],
  'bird': [
    _PromptTemplate('This animal can flap and fly. It is a ___.', showVisualHint: true),
  ],
  'fish': [
    _PromptTemplate('This animal swims in water. It is a ___.', showVisualHint: true),
  ],
  'rabbit': [
    _PromptTemplate('This animal has long ears and hops. It is a ___.', showVisualHint: true),
  ],
  'duck': [
    _PromptTemplate('This animal has a beak and says quack. It is a ___.', showVisualHint: true),
  ],
  'cow': [
    _PromptTemplate('This farm animal says moo. It is a ___.', showVisualHint: true),
  ],
  'horse': [
    _PromptTemplate('I can ride this large farm animal. It is a ___.', showVisualHint: true),
  ],
  'lion': [
    _PromptTemplate('This big wild cat has a roar. It is a ___.', showVisualHint: true),
  ],
  'tiger': [
    _PromptTemplate('This big wild cat has stripes. It is a ___.', showVisualHint: true),
  ],
  'elephant': [
    _PromptTemplate('This large animal has a trunk. It is an ___.', showVisualHint: true),
  ],
  'monkey': [
    _PromptTemplate('This animal likes to climb trees. It is a ___.', showVisualHint: true),
  ],
  'bear': [
    _PromptTemplate('This big furry animal can growl. It is a ___.', showVisualHint: true),
  ],
  'frog': [
    _PromptTemplate('This small animal can hop and croak. It is a ___.', showVisualHint: true),
  ],
  'sheep': [
    _PromptTemplate('This farm animal has wool. It is a ___.', showVisualHint: true),
  ],
  'goat': [
    _PromptTemplate('This farm animal can have horns. It is a ___.', showVisualHint: true),
  ],
};
