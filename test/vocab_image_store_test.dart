import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_aac_speech_learning/models/child_model.dart';
import 'package:smart_aac_speech_learning/providers/child_provider.dart';
import 'package:smart_aac_speech_learning/providers/vocab_provider.dart';
import 'package:smart_aac_speech_learning/services/vocab_image_store.dart';
import 'package:smart_aac_speech_learning/services/vocab_service.dart';

void main() {
  group('VocabImageStore', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('vocab_images_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('saveImage creates a file and index entry', () async {
      final store = VocabImageStore(
        baseDirectoryBuilder: () async => tempDir,
      );
      addTearDown(store.dispose);

      await store.saveImage(
        childId: 'child-1',
        itemId: 'item-1',
        bytes: Uint8List.fromList(const [1, 2, 3, 4]),
        extension: 'png',
      );

      final paths = await store.watchImagePaths('child-1').first;
      final savedPath = paths['item-1'];

      expect(savedPath, isNotNull);
      expect(File(savedPath!).existsSync(), isTrue);
      expect(File('${tempDir.path}${Platform.pathSeparator}vocab_images_index.json')
          .existsSync(), isTrue);
    });

    test('deleteImage removes the file and index entry', () async {
      final store = VocabImageStore(
        baseDirectoryBuilder: () async => tempDir,
      );
      addTearDown(store.dispose);

      await store.saveImage(
        childId: 'child-1',
        itemId: 'item-1',
        bytes: Uint8List.fromList(const [5, 6, 7]),
        extension: 'jpg',
      );

      final beforeDelete = await store.watchImagePaths('child-1').first;
      final savedPath = beforeDelete['item-1'];
      expect(savedPath, isNotNull);

      await store.deleteImage(childId: 'child-1', itemId: 'item-1');

      final afterDelete = await store.watchImagePaths('child-1').first;
      expect(afterDelete, isEmpty);
      expect(File(savedPath!).existsSync(), isFalse);
    });

    test('reload restores saved paths from the index', () async {
      final storeA = VocabImageStore(
        baseDirectoryBuilder: () async => tempDir,
      );

      await storeA.saveImage(
        childId: 'child-1',
        itemId: 'item-1',
        bytes: Uint8List.fromList(const [9, 8, 7]),
        extension: 'png',
      );

      final savedPath = (await storeA.watchImagePaths('child-1').first)['item-1'];
      storeA.dispose();

      final storeB = VocabImageStore(
        baseDirectoryBuilder: () async => tempDir,
      );
      addTearDown(storeB.dispose);

      final restoredPaths = await storeB.watchImagePaths('child-1').first;
      expect(restoredPaths['item-1'], savedPath);
    });

    test('reload drops missing files from the index', () async {
      final storeA = VocabImageStore(
        baseDirectoryBuilder: () async => tempDir,
      );

      await storeA.saveImage(
        childId: 'child-1',
        itemId: 'item-1',
        bytes: Uint8List.fromList(const [2, 4, 6]),
        extension: 'png',
      );

      final savedPath = (await storeA.watchImagePaths('child-1').first)['item-1'];
      storeA.dispose();

      await File(savedPath!).delete();

      final storeB = VocabImageStore(
        baseDirectoryBuilder: () async => tempDir,
      );
      addTearDown(storeB.dispose);

      final restoredPaths = await storeB.watchImagePaths('child-1').first;
      expect(restoredPaths, isEmpty);
    });
  });

  test('allVocabItemsProvider overlays local images on top of remote metadata', () async {
    final fakeService = _FakeVocabService();
    final fakeStore = _FakeVocabImageStore();
    final container = ProviderContainer(
      overrides: [
        vocabServiceProvider.overrideWithValue(fakeService),
        vocabImageStoreProvider.overrideWithValue(fakeStore),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await fakeService.dispose();
      fakeStore.dispose();
    });

    container.read(activeChildProvider.notifier).state = const ChildModel(
      id: 'child-1',
      name: 'Ava',
      avatarEmoji: '😀',
      avatarGradientStart: '#000000',
      avatarGradientEnd: '#111111',
      difficulty: 'beginner',
      qaMode: 2,
      linkedUsers: ['user-1'],
      createdBy: 'user-1',
      isActiveOnDevice: true,
    );

    final completer = Completer<List<VocabItem>>();
    final subscription = container.listen<AsyncValue<List<VocabItem>>>(
      allVocabItemsProvider,
      (previous, next) {
        final items = next.valueOrNull;
        if (items != null && !completer.isCompleted) {
          completer.complete(items);
        }
      },
      fireImmediately: false,
    );
    addTearDown(subscription.close);

    fakeService.emit(const [
      VocabItem(
        id: 'item-1',
        word: 'Apple',
        emoji: '🍎',
        category: 'Food',
        imageUrl: 'https://example.com/apple.png',
      ),
    ]);
    fakeStore.emit({'item-1': 'C:\\local\\apple.png'});

    final items = await completer.future;
    expect(items, hasLength(1));
    expect(items.single.localImagePath, 'C:\\local\\apple.png');
    expect(items.single.imageUrl, 'https://example.com/apple.png');
  });
}

class _FakeVocabService extends VocabService {
  final StreamController<List<VocabItem>> _itemsController =
      StreamController<List<VocabItem>>.broadcast();

  @override
  Stream<List<VocabItem>> watchAllVocabItems(String childId) {
    return _itemsController.stream;
  }

  @override
  Stream<List<VocabItem>> watchVocabItems(String childId, String category) {
    return _itemsController.stream.map(
      (items) => items.where((item) => item.category == category).toList(),
    );
  }

  @override
  Stream<List<String>> watchCategories(String childId) {
    return _itemsController.stream.map(
      (items) => items
          .map((item) => item.category)
          .toSet()
          .toList()
        ..sort(),
    );
  }

  void emit(List<VocabItem> items) {
    _itemsController.add(items);
  }

  Future<void> dispose() {
    return _itemsController.close();
  }
}

class _FakeVocabImageStore extends VocabImageStore {
  _FakeVocabImageStore()
      : super(baseDirectoryBuilder: () async => Directory.systemTemp);

  final StreamController<Map<String, String>> _controller =
      StreamController<Map<String, String>>.broadcast();

  @override
  Stream<Map<String, String>> watchImagePaths(String childId) {
    return _controller.stream;
  }

  void emit(Map<String, String> paths) {
    _controller.add(paths);
  }

  @override
  void dispose() {
    _controller.close();
  }
}
