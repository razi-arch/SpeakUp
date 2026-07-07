import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/vocab_image_store.dart';
import '../services/vocab_service.dart';
import 'child_provider.dart';

final vocabServiceProvider = Provider<VocabService>((ref) => VocabService());
final vocabImageStoreProvider = Provider<VocabImageStore>((ref) {
  final store = VocabImageStore();
  ref.onDispose(store.dispose);
  return store;
});

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

final categoriesProvider = StreamProvider<List<String>>((ref) {
  final child = ref.watch(activeChildProvider);
  if (child == null) return const Stream.empty();
  return ref.watch(vocabServiceProvider).watchCategories(child.id);
});

// All vocab items for the active child — used by Speech Practice
final allVocabItemsProvider = StreamProvider<List<VocabItem>>((ref) {
  final child = ref.watch(activeChildProvider);
  if (child == null) return const Stream.empty();
  return _watchMergedItems(
    itemsStream: ref.watch(vocabServiceProvider).watchAllVocabItems(child.id),
    imagePathsStream: ref.watch(vocabImageStoreProvider).watchImagePaths(child.id),
  );
});

// Admin vocab manager — watches all items for an arbitrary child
final adminAllVocabProvider =
    StreamProvider.family<List<VocabItem>, String>((ref, childId) {
  return _watchMergedItems(
    itemsStream: ref.watch(vocabServiceProvider).watchAllVocabItems(childId),
    imagePathsStream: ref.watch(vocabImageStoreProvider).watchImagePaths(childId),
  );
});

final vocabItemsProvider = StreamProvider<List<VocabItem>>((ref) {
  final child    = ref.watch(activeChildProvider);
  final category = ref.watch(selectedCategoryProvider);
  if (child == null || category == null) return const Stream.empty();
  return _watchMergedItems(
    itemsStream: ref.watch(vocabServiceProvider).watchVocabItems(child.id, category),
    imagePathsStream: ref.watch(vocabImageStoreProvider).watchImagePaths(child.id),
  );
});

Stream<List<VocabItem>> _watchMergedItems({
  required Stream<List<VocabItem>> itemsStream,
  required Stream<Map<String, String>> imagePathsStream,
}) {
  return _combineLatest2(
    itemsStream,
    imagePathsStream,
    (items, imagePaths) => items
        .map((item) => item.copyWith(localImagePath: imagePaths[item.id]))
        .toList(growable: false),
  );
}

Stream<R> _combineLatest2<A, B, R>(
  Stream<A> streamA,
  Stream<B> streamB,
  R Function(A valueA, B valueB) combine,
) {
  late final StreamController<R> controller;
  StreamSubscription<A>? subscriptionA;
  StreamSubscription<B>? subscriptionB;
  A? latestA;
  B? latestB;
  var hasA = false;
  var hasB = false;

  void emitIfReady() {
    if (hasA && hasB) {
      controller.add(combine(latestA as A, latestB as B));
    }
  }

  controller = StreamController<R>(
    onListen: () {
      subscriptionA = streamA.listen(
        (value) {
          latestA = value;
          hasA = true;
          emitIfReady();
        },
        onError: controller.addError,
      );
      subscriptionB = streamB.listen(
        (value) {
          latestB = value;
          hasB = true;
          emitIfReady();
        },
        onError: controller.addError,
      );
    },
    onCancel: () async {
      await subscriptionA?.cancel();
      await subscriptionB?.cancel();
    },
  );

  return controller.stream;
}
