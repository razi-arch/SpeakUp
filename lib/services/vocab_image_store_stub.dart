import 'dart:async';
import 'dart:typed_data';

class VocabImageSaveException implements Exception {
  const VocabImageSaveException({
    required this.userMessage,
    required this.debugMessage,
  });

  final String userMessage;
  final String debugMessage;

  @override
  String toString() => 'VocabImageSaveException($debugMessage)';
}

class VocabImageStore {
  VocabImageStore({
    Future<Object?> Function()? baseDirectoryBuilder,
  });

  Stream<Map<String, String>> watchImagePaths(String childId) async* {
    yield const {};
  }

  Future<void> saveImage({
    required String childId,
    required String itemId,
    required Uint8List bytes,
    required String extension,
  }) {
    throw const VocabImageSaveException(
      userMessage: 'Local pictures are not supported on this platform.',
      debugMessage: 'VocabImageStore is running in the unsupported stub mode.',
    );
  }

  Future<void> deleteImage({
    required String childId,
    required String itemId,
  }) async {}

  void dispose() {}
}
