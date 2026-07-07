import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

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
    Future<Directory> Function()? baseDirectoryBuilder,
  }) : _baseDirectoryBuilder =
            baseDirectoryBuilder ?? _defaultBaseDirectoryBuilder;

  final Future<Directory> Function() _baseDirectoryBuilder;
  final StreamController<Map<String, Map<String, String>>> _controller =
      StreamController<Map<String, Map<String, String>>>.broadcast();

  Map<String, Map<String, String>> _pathsByChild = const {};
  Future<void>? _loadFuture;
  bool _loaded = false;

  Stream<Map<String, String>> watchImagePaths(String childId) async* {
    await _ensureLoaded();
    yield _pathsForChild(childId, _pathsByChild);
    yield* _controller.stream.map((allPaths) => _pathsForChild(childId, allPaths));
  }

  Future<void> saveImage({
    required String childId,
    required String itemId,
    required Uint8List bytes,
    required String extension,
  }) async {
    await _ensureLoaded();

    final normalizedExtension = _normalizeExtension(extension);
    final destinationPath = await _buildImagePath(
      childId: childId,
      itemId: itemId,
      extension: normalizedExtension,
    );

    try {
      final nextFile = File(destinationPath);
      await nextFile.parent.create(recursive: true);
      await nextFile.writeAsBytes(bytes, flush: true);

      final previousPath = _pathsByChild[childId]?[itemId];
      if (previousPath != null && previousPath != destinationPath) {
        await _deleteFileIfPresent(previousPath);
      }

      final nextPaths = _clonePaths();
      final childPaths = nextPaths.putIfAbsent(childId, () => <String, String>{});
      childPaths[itemId] = destinationPath;

      await _replacePaths(nextPaths);
      _logStep(
        'Saved local vocab image childId=$childId itemId=$itemId path=$destinationPath',
      );
    } catch (error, stackTrace) {
      _logStep(
        'Failed to save local vocab image childId=$childId itemId=$itemId',
        error: error,
        stackTrace: stackTrace,
      );
      throw VocabImageSaveException(
        userMessage: 'We could not save that picture on this device.',
        debugMessage: error.toString().trim(),
      );
    }
  }

  Future<void> deleteImage({
    required String childId,
    required String itemId,
  }) async {
    await _ensureLoaded();

    final existingPath = _pathsByChild[childId]?[itemId];
    if (existingPath == null) {
      return;
    }

    await _deleteFileIfPresent(existingPath);

    final nextPaths = _clonePaths();
    final childPaths = nextPaths[childId];
    childPaths?.remove(itemId);
    if (childPaths != null && childPaths.isEmpty) {
      nextPaths.remove(childId);
    }

    await _replacePaths(nextPaths);
    _logStep(
      'Deleted local vocab image childId=$childId itemId=$itemId path=$existingPath',
    );
  }

  void dispose() {
    _controller.close();
  }

  Future<void> _ensureLoaded() {
    if (_loaded) {
      return Future.value();
    }
    return _loadFuture ??= _loadIndex();
  }

  Future<void> _loadIndex() async {
    try {
      final file = await _indexFile();
      if (!await file.exists()) {
        _pathsByChild = const {};
      } else {
        final decoded = jsonDecode(await file.readAsString());
        _pathsByChild = await _reconcileLoadedPaths(_parseDecodedIndex(decoded));
      }
    } catch (error, stackTrace) {
      _pathsByChild = const {};
      _logStep(
        'Could not load local vocab image index. Starting empty.',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _loaded = true;
      _loadFuture = null;
      _emit();
    }
  }

  Map<String, Map<String, String>> _parseDecodedIndex(Object? decoded) {
    if (decoded is! Map) {
      return <String, Map<String, String>>{};
    }

    final result = <String, Map<String, String>>{};
    for (final entry in decoded.entries) {
      final childId = entry.key.toString().trim();
      final value = entry.value;
      if (childId.isEmpty || value is! Map) {
        continue;
      }

      final childPaths = <String, String>{};
      for (final childEntry in value.entries) {
        final itemId = childEntry.key.toString().trim();
        final path = childEntry.value?.toString().trim();
        if (itemId.isEmpty || path == null || path.isEmpty) {
          continue;
        }
        childPaths[itemId] = path;
      }

      if (childPaths.isNotEmpty) {
        result[childId] = childPaths;
      }
    }
    return result;
  }

  Future<Map<String, Map<String, String>>> _reconcileLoadedPaths(
    Map<String, Map<String, String>> loadedPaths,
  ) async {
    final nextPaths = <String, Map<String, String>>{};

    for (final childEntry in loadedPaths.entries) {
      final childPaths = <String, String>{};
      for (final imageEntry in childEntry.value.entries) {
        if (await File(imageEntry.value).exists()) {
          childPaths[imageEntry.key] = imageEntry.value;
        }
      }
      if (childPaths.isNotEmpty) {
        nextPaths[childEntry.key] = childPaths;
      }
    }

    return nextPaths;
  }

  Future<void> _replacePaths(Map<String, Map<String, String>> nextPaths) async {
    _pathsByChild = nextPaths;
    await _writeIndex();
    _emit();
  }

  Future<void> _writeIndex() async {
    final file = await _indexFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(_pathsByChild), flush: true);
  }

  Future<File> _indexFile() async {
    final baseDir = await _baseDirectoryBuilder();
    return File('${baseDir.path}${Platform.pathSeparator}vocab_images_index.json');
  }

  Future<String> _buildImagePath({
    required String childId,
    required String itemId,
    required String extension,
  }) async {
    final baseDir = await _baseDirectoryBuilder();
    final childDir = Directory(
      '${baseDir.path}${Platform.pathSeparator}images'
      '${Platform.pathSeparator}$childId',
    );
    await childDir.create(recursive: true);
    return '${childDir.path}${Platform.pathSeparator}$itemId.$extension';
  }

  Map<String, Map<String, String>> _clonePaths() {
    final nextPaths = <String, Map<String, String>>{};
    for (final entry in _pathsByChild.entries) {
      nextPaths[entry.key] = Map<String, String>.from(entry.value);
    }
    return nextPaths;
  }

  Map<String, String> _pathsForChild(
    String childId,
    Map<String, Map<String, String>> allPaths,
  ) {
    return Map.unmodifiable(allPaths[childId] ?? const <String, String>{});
  }

  Future<void> _deleteFileIfPresent(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  void _emit() {
    if (_controller.isClosed) {
      return;
    }

    _controller.add(_clonePaths());
  }

  String _normalizeExtension(String extension) {
    final normalized = extension.trim().toLowerCase();
    if (normalized.isEmpty) {
      return 'jpg';
    }
    return normalized.startsWith('.') ? normalized.substring(1) : normalized;
  }

  void _logStep(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: 'VocabImageStore',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

Future<Directory> _defaultBaseDirectoryBuilder() async {
  final documentsDir = await getApplicationDocumentsDirectory();
  return Directory(
    '${documentsDir.path}${Platform.pathSeparator}vocab_images',
  );
}
