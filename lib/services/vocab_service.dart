import 'package:cloud_firestore/cloud_firestore.dart';

class VocabItem {
  static const Object _unset = Object();

  final String id;
  final String word;
  final String emoji;
  final String category;
  final String? imageUrl;
  final String? localImagePath;
  final String? audioUrl;

  const VocabItem({
    required this.id,
    required this.word,
    required this.emoji,
    required this.category,
    this.imageUrl,
    this.localImagePath,
    this.audioUrl,
  });

  factory VocabItem.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VocabItem(
      id: doc.id,
      word: data['word'] as String,
      emoji: data['emoji'] as String,
      category: data['category'] as String,
      imageUrl: data['imageUrl'] as String?,
      localImagePath: null,
      audioUrl: data['audioUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'word': word,
    'emoji': emoji,
    'category': category,
    'imageUrl': imageUrl,
    'audioUrl': audioUrl,
  };

  VocabItem copyWith({
    String? id,
    String? word,
    String? emoji,
    String? category,
    Object? imageUrl = _unset,
    Object? localImagePath = _unset,
    Object? audioUrl = _unset,
  }) {
    return VocabItem(
      id: id ?? this.id,
      word: word ?? this.word,
      emoji: emoji ?? this.emoji,
      category: category ?? this.category,
      imageUrl: identical(imageUrl, _unset) ? this.imageUrl : imageUrl as String?,
      localImagePath: identical(localImagePath, _unset)
          ? this.localImagePath
          : localImagePath as String?,
      audioUrl: identical(audioUrl, _unset) ? this.audioUrl : audioUrl as String?,
    );
  }
}

class VocabService {
  final _db = FirebaseFirestore.instance;

  Future<List<VocabItem>> getVocabItems(String childId, String category) async {
    final snap = await _db
        .collection('vocab')
        .doc(childId)
        .collection('items')
        .where('category', isEqualTo: category)
        .get();
    return snap.docs.map(VocabItem.fromDoc).toList();
  }

  Stream<List<VocabItem>> watchVocabItems(String childId, String category) {
    return _db
        .collection('vocab')
        .doc(childId)
        .collection('items')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snap) => snap.docs.map(VocabItem.fromDoc).toList());
  }

  Future<String> addVocabItem(String childId, VocabItem item) async {
    final doc = await _db
        .collection('vocab')
        .doc(childId)
        .collection('items')
        .add(item.toJson());
    return doc.id;
  }

  Future<void> updateVocabItem(
      String childId, String itemId, Map<String, dynamic> fields) {
    return _db
        .collection('vocab')
        .doc(childId)
        .collection('items')
        .doc(itemId)
        .update(fields);
  }

  Future<void> deleteVocabItem(String childId, String itemId) {
    return _db
        .collection('vocab')
        .doc(childId)
        .collection('items')
        .doc(itemId)
        .delete();
  }

  Stream<List<VocabItem>> watchAllVocabItems(String childId) {
    return _db
        .collection('vocab')
        .doc(childId)
        .collection('items')
        .snapshots()
        .map((snap) => snap.docs.map(VocabItem.fromDoc).toList());
  }

  Stream<List<String>> watchCategories(String childId) {
    return _db
        .collection('vocab')
        .doc(childId)
        .collection('items')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => d.data()['category'] as String)
            .toSet()
            .toList()
          ..sort());
  }
}
