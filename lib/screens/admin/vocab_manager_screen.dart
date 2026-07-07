import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/child_model.dart';
import '../../providers/child_provider.dart';
import '../../providers/vocab_provider.dart';
import '../../services/vocab_image_store.dart';
import '../../services/vocab_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text.dart';
import '../../widgets/admin_sidebar.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';
import '../../widgets/vocab_image.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────

class VocabManagerScreen extends ConsumerStatefulWidget {
  const VocabManagerScreen({required this.childId, super.key});
  final String childId;

  @override
  ConsumerState<VocabManagerScreen> createState() =>
      _VocabManagerScreenState();
}

class _VocabManagerScreenState extends ConsumerState<VocabManagerScreen> {
  String? _selectedCategory; // null = show all
  VocabItem? _editingItem;   // null = add mode when _showForm is true
  bool _showForm = false;

  void _openAdd() => setState(() {
        _editingItem = null;
        _showForm    = true;
      });

  void _openEdit(VocabItem item) => setState(() {
        _editingItem = item;
        _showForm    = true;
      });

  void _closeForm() => setState(() {
        _showForm    = false;
        _editingItem = null;
      });

  Future<void> _setQaMode(int mode) =>
      ref.read(childServiceProvider).updateChild(widget.childId, {'qaMode': mode});

  @override
  Widget build(BuildContext context) {
    final allAsync  = ref.watch(adminAllVocabProvider(widget.childId));
    final children  = ref.watch(linkedChildrenProvider).valueOrNull ?? [];

    ChildModel? child;
    for (final c in children) {
      if (c.id == widget.childId) { child = c; break; }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0EDE8),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminSidebar(
                currentPath: '/admin/vocab/${widget.childId}'),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(),
                  const Divider(color: AppColors.ink4, height: 1),
                  // Q&A mode toggle
                  if (child != null) ...[
                    _QaModeBar(
                      qaMode: child.qaMode,
                      onToggle: _setQaMode,
                    ),
                    const Divider(color: AppColors.ink4, height: 1),
                  ],
                  Expanded(
                    child: allAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.green, strokeWidth: 3),
                      ),
                      error: (error, stackTrace) => Center(
                        child: Text('Could not load vocab',
                            style: AppText.body(color: AppColors.ink3)),
                      ),
                      data: (items) => _buildContent(items),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ).animate()
          .fadeIn(duration: AppMotion.slow, curve: AppMotion.easeOut),
      ),
    );
  }

  Widget _buildContent(List<VocabItem> items) {
    // Derive categories from all items
    final categories = items
        .map((i) => i.category)
        .toSet()
        .toList()
      ..sort();

    // Filter
    final filtered = _selectedCategory == null
        ? items
        : items.where((i) => i.category == _selectedCategory).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Items panel ────────────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Category tabs
              _CategoryTabs(
                categories: categories,
                selected: _selectedCategory,
                onSelect: (cat) =>
                    setState(() => _selectedCategory = cat),
                onAddItem: _openAdd,
              ),
              const Divider(color: AppColors.ink4, height: 1),
              // Item list
              Expanded(
                child: _ItemList(
                  items: filtered,
                  onTap: _openEdit,
                  onDelete: (item) => _confirmDelete(item),
                ),
              ),
            ],
          ),
        ),
        // ── Vertical divider ───────────────────────────────────
        Container(
          width: 1.5,
          color: AppColors.ink4,
        ),
        // ── Form panel ─────────────────────────────────────────
        SizedBox(
          width: 360,
          child: _FormPanel(
            childId:    widget.childId,
            item:       _editingItem,
            categories: categories,
            showForm:   _showForm,
            onDone:     _closeForm,
            onCancel:   _closeForm,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(VocabItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${item.word}"?',
            style: AppText.title()),
        content: Text(
          'This will remove the word from all vocab activities.',
          style: AppText.body(color: AppColors.ink3),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: AppText.button(color: AppColors.rose)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref
          .read(vocabServiceProvider)
          .deleteVocabItem(widget.childId, item.id);
      try {
        await ref.read(vocabImageStoreProvider).deleteImage(
              childId: widget.childId,
              itemId: item.id,
            );
      } catch (_) {}
      if (mounted && _editingItem?.id == item.id) _closeForm();
    }
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 16, 14),
      color: AppColors.bgCard,
      child: Row(
        children: [
          Text('Vocab Manager', style: AppText.heading()),
          const Spacer(),
          GestureDetector(
            onTap: () => context.go('/admin/dashboard'),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text('← Dashboard',
                  style: AppText.caption(color: AppColors.ink3)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── QA mode bar ──────────────────────────────────────────────────────────────

class _QaModeBar extends StatelessWidget {
  const _QaModeBar({required this.qaMode, required this.onToggle});

  final int qaMode;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgCard,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          Text('Q&A mode for this child:',
              style: AppText.caption()),
          const SizedBox(width: 12),
          _ModeChip(
            label: '2 choices (easier)',
            active: qaMode == 2,
            onTap: () => onToggle(2),
          ),
          const SizedBox(width: 8),
          _ModeChip(
            label: '4 choices (harder)',
            active: qaMode == 4,
            onTap: () => onToggle(4),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip(
      {required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.green : AppColors.ink5,
          borderRadius: AppRadius.pill,
        ),
        child: Text(
          label,
          style: AppText.caption(
              color: active ? Colors.white : AppColors.ink2),
        ),
      ),
    );
  }
}

// ─── Category tabs ────────────────────────────────────────────────────────────

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({
    required this.categories,
    required this.selected,
    required this.onSelect,
    required this.onAddItem,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelect;
  final VoidCallback onAddItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgCard,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _TabChip(
                    label: 'All',
                    active: selected == null,
                    onTap: () => onSelect(null),
                  ),
                  for (final cat in categories) ...[
                    const SizedBox(width: 6),
                    _TabChip(
                      label: cat,
                      active: selected == cat,
                      onTap: () => onSelect(cat),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onAddItem,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: AppRadius.pill,
                boxShadow: AppShadows.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text('Add Item',
                      style: AppText.caption(color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip(
      {required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.skyLight : Colors.transparent,
          borderRadius: AppRadius.pill,
          border: Border.all(
            color: active ? AppColors.sky : AppColors.ink4,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppText.caption(
              color: active ? AppColors.sky : AppColors.ink2),
        ),
      ),
    );
  }
}

// ─── Item list ────────────────────────────────────────────────────────────────

class _ItemList extends StatelessWidget {
  const _ItemList({
    required this.items,
    required this.onTap,
    required this.onDelete,
  });

  final List<VocabItem> items;
  final ValueChanged<VocabItem> onTap;
  final ValueChanged<VocabItem> onDelete;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📚', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text('No vocab items yet', style: AppText.heading()),
            const SizedBox(height: 6),
            Text('Tap "Add Item" to create the first word.',
                style: AppText.body(color: AppColors.ink3)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _ItemTile(
        item: items[i],
        onTap: () => onTap(items[i]),
        onDelete: () => onDelete(items[i]),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  final VocabItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: AppRadius.lg,
          boxShadow: AppShadows.xs,
        ),
        child: Row(
          children: [
            // Thumbnail
            _Thumbnail(item: item),
            const SizedBox(width: 12),
            // Word + category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.word, style: AppText.title()),
                  Text(item.category,
                      style: AppText.caption(color: AppColors.ink3)),
                ],
              ),
            ),
            // Audio indicator
            if (item.audioUrl != null) ...[
              const Icon(Icons.headphones_rounded,
                  size: 14, color: AppColors.ink3),
              const SizedBox(width: 8),
            ],
            // Delete
            GestureDetector(
              onTap: onDelete,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: AppColors.ink3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.item});
  final VocabItem item;

  @override
  Widget build(BuildContext context) {
    return VocabImage(
      localImagePath: item.localImagePath,
      imageUrl: item.imageUrl,
      width: 48,
      height: 48,
      borderRadius: AppRadius.sm,
      fallback: _EmojiFallback(item),
      placeholder: Container(
        width: 48,
        height: 48,
        color: AppColors.ink5,
        alignment: Alignment.center,
        child: Text(item.emoji, style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}

class _EmojiFallback extends StatelessWidget {
  const _EmojiFallback(this.item);
  final VocabItem item;

  @override
  Widget build(BuildContext context) {
    final trimmedEmoji = item.emoji.trim();
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.bgRaised,
        borderRadius: AppRadius.sm,
      ),
      alignment: Alignment.center,
      child: trimmedEmoji.isNotEmpty
          ? Text(trimmedEmoji, style: const TextStyle(fontSize: 24))
          : const Icon(
              Icons.image_outlined,
              size: 20,
              color: AppColors.ink3,
            ),
    );
  }
}

// ─── Form panel ───────────────────────────────────────────────────────────────

class _FormPanel extends ConsumerStatefulWidget {
  const _FormPanel({
    required this.childId,
    required this.item,
    required this.categories,
    required this.showForm,
    required this.onDone,
    required this.onCancel,
  });

  final String childId;
  final VocabItem? item;
  final List<String> categories;
  final bool showForm;
  final VoidCallback onDone;
  final VoidCallback onCancel;

  @override
  ConsumerState<_FormPanel> createState() => _FormPanelState();
}

class _FormPanelState extends ConsumerState<_FormPanel> {
  final _wordCtrl     = TextEditingController();
  final _emojiCtrl    = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _tts          = FlutterTts();
  final _picker       = ImagePicker();

  Uint8List? _pendingImageBytes;
  String? _pendingImageExtension;
  bool _loadingImage = false;
  bool _removeImage = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.45);
    _populate(widget.item);
  }

  @override
  void didUpdateWidget(_FormPanel old) {
    super.didUpdateWidget(old);
    if (old.item?.id != widget.item?.id ||
        old.showForm != widget.showForm) {
      _populate(widget.item);
    }
  }

  @override
  void dispose() {
    _wordCtrl.dispose();
    _emojiCtrl.dispose();
    _categoryCtrl.dispose();
    _tts.stop();
    super.dispose();
  }

  void _populate(VocabItem? item) {
    _wordCtrl.text     = item?.word     ?? '';
    _emojiCtrl.text    = item?.emoji    ?? '';
    _categoryCtrl.text = item?.category ?? '';
    _pendingImageBytes = null;
    _pendingImageExtension = null;
    _removeImage = false;
    _error    = null;
  }

  // ── Image upload ───────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    try {
      final selected = await _selectImageFile();
      if (selected == null || !mounted) return;

      setState(() {
        _loadingImage = true;
        _error = null;
      });
      if (mounted) {
        setState(() {
          _pendingImageBytes = selected.bytes;
          _pendingImageExtension = _fileExtension(selected.name);
          _removeImage = false;
          _loadingImage = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingImage = false;
          _error = 'We could not open that picture. Try a JPG or PNG file.';
        });
      }
    }
  }

  Future<_SelectedImage?> _selectImageFile() async {
    if (_isDesktopPlatform) {
      const typeGroup = XTypeGroup(
        label: 'images',
        extensions: ['jpg', 'jpeg', 'png', 'webp'],
      );
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) return null;
      return _SelectedImage(
        name: file.name,
        bytes: await file.readAsBytes(),
      );
    }

    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (file == null) return null;
    return _SelectedImage(
      name: file.name,
      bytes: await file.readAsBytes(),
    );
  }

  bool get _isDesktopPlatform {
    if (kIsWeb) return false;

    return switch (defaultTargetPlatform) {
      TargetPlatform.windows ||
      TargetPlatform.macOS ||
      TargetPlatform.linux => true,
      _ => false,
    };
  }

  String _fileExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == fileName.length - 1) {
      return 'jpg';
    }
    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  void _clearImage() {
    setState(() {
      _pendingImageBytes = null;
      _pendingImageExtension = null;
      _removeImage = true;
    });
  }

  // ── Save / delete ──────────────────────────────────────────────────────────

  Future<void> _save() async {
    final word     = _wordCtrl.text.trim();
    final emoji    = _emojiCtrl.text.trim();
    final category = _categoryCtrl.text.trim();

    if (word.isEmpty || category.isEmpty) {
      setState(() => _error = 'Word and category are required.');
      return;
    }

    if (emoji.isEmpty && !_hasAnyImage) {
      setState(() => _error = 'Add an emoji or upload a picture.');
      return;
    }

    setState(() { _saving = true; _error = null; });
    final imageStore = ref.read(vocabImageStoreProvider);
    try {
      final item = VocabItem(
        id:        widget.item?.id ?? '',
        word:      word,
        emoji:     emoji,
        category:  category,
        imageUrl:  _pendingImageBytes != null || _removeImage
            ? null
            : widget.item?.imageUrl,
        audioUrl:  widget.item?.audioUrl,
      );
      late final String itemId;
      if (widget.item != null) {
        await ref.read(vocabServiceProvider)
            .updateVocabItem(widget.childId, widget.item!.id, item.toJson());
        itemId = widget.item!.id;
      } else {
        itemId = await ref.read(vocabServiceProvider)
            .addVocabItem(widget.childId, item);
      }

      String? imageWarning;
      try {
        if (_removeImage) {
          await imageStore.deleteImage(
            childId: widget.childId,
            itemId: itemId,
          );
        } else if (_pendingImageBytes != null) {
          await imageStore.saveImage(
            childId: widget.childId,
            itemId: itemId,
            bytes: _pendingImageBytes!,
            extension: _pendingImageExtension ?? 'jpg',
          );
        }
      } on VocabImageSaveException catch (error) {
        imageWarning = widget.item == null
            ? 'Word saved, but picture could not be saved on this device.'
            : error.userMessage;
      } catch (_) {
        imageWarning = widget.item == null
            ? 'Word saved, but picture could not be saved on this device.'
            : 'Word saved, but picture could not be updated on this device.';
      }

      if (!mounted) return;
      setState(() => _saving = false);
      widget.onDone();
      if (imageWarning != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(imageWarning)),
        );
      }
    } on VocabImageSaveException catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.userMessage;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Save failed. Please try again.';
        });
      }
    }
  }

  bool get _hasAnyImage {
    if (_pendingImageBytes != null) {
      return true;
    }
    if (_removeImage) {
      return false;
    }

    final localPath = widget.item?.localImagePath?.trim();
    if (localPath != null && localPath.isNotEmpty) {
      return true;
    }

    final remoteUrl = widget.item?.imageUrl?.trim();
    return remoteUrl != null && remoteUrl.isNotEmpty;
  }

  String? get _previewLocalImagePath {
    if (_pendingImageBytes != null || _removeImage) {
      return null;
    }
    return widget.item?.localImagePath;
  }

  String? get _previewImageUrl {
    if (_pendingImageBytes != null || _removeImage) {
      return null;
    }
    return widget.item?.imageUrl;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showForm) {
      return Container(
        color: AppColors.bgCard,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.note_add_rounded,
                  size: 48, color: AppColors.ink4),
              const SizedBox(height: 12),
              Text('Select an item to edit',
                  style: AppText.body(color: AppColors.ink3)),
              const SizedBox(height: 4),
              Text('or tap "Add Item" above',
                  style: AppText.caption(color: AppColors.ink4)),
            ],
          ),
        ),
      );
    }

    final isEdit = widget.item != null;

    return Container(
      color: AppColors.bgCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Panel header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: AppColors.ink4, width: 1)),
            ),
            child: Row(
              children: [
                Text(isEdit ? 'Edit item' : 'New item',
                    style: AppText.title()),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onCancel,
                  child: const Icon(Icons.close_rounded,
                      color: AppColors.ink3, size: 20),
                ),
              ],
            ),
          ),
          // Form body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Word
                  _label('Word'),
                  const SizedBox(height: 6),
                  _field(_wordCtrl, hint: 'e.g. Apple'),
                  const SizedBox(height: 14),
                  // Emoji
                  _label('Emoji'),
                  const SizedBox(height: 6),
                  _field(_emojiCtrl, hint: '🍎'),
                  const SizedBox(height: 6),
                  Text(
                    'You can leave this blank if you upload a picture.',
                    style: AppText.caption(color: AppColors.ink3),
                  ),
                  const SizedBox(height: 14),
                  // Category
                  _label('Category'),
                  const SizedBox(height: 6),
                  _field(_categoryCtrl, hint: 'e.g. Food'),
                  if (widget.categories.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final cat in widget.categories)
                          GestureDetector(
                            onTap: () => setState(
                                () => _categoryCtrl.text = cat),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.ink5,
                                borderRadius: AppRadius.pill,
                              ),
                              child: Text(cat,
                                  style: AppText.caption(
                                      color: AppColors.ink2)),
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  // Image
                  _label('Image (optional)'),
                  const SizedBox(height: 8),
                  _ImageArea(
                    localImagePath: _previewLocalImagePath,
                    imageUrl: _previewImageUrl,
                    memoryBytes: _pendingImageBytes,
                    loading: _loadingImage,
                    onPick: _pickImage,
                    onClear: _clearImage,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Best results: square JPG or PNG, around 512 x 512 pixels or larger. The app will resize big images automatically.',
                    style: AppText.caption(color: AppColors.ink3),
                  ),
                  const SizedBox(height: 14),
                  // Audio test
                  SecondaryButton(
                    label: '🔊  Preview word',
                    onPressed: () {
                      final w = _wordCtrl.text.trim();
                      if (w.isNotEmpty) _tts.speak(w);
                    },
                  ),
                  // Error
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.roseLight,
                        borderRadius: AppRadius.md,
                        border: Border.all(
                            color: AppColors.roseMid, width: 1.5),
                      ),
                      child: Text(_error!,
                          style:
                              AppText.caption(color: AppColors.rose)),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Save
                  _saving
                      ? Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            borderRadius: AppRadius.pill,
                          ),
                          alignment: Alignment.center,
                          child: const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          ),
                        )
                      : PrimaryButton(
                          label: isEdit ? 'Save Changes' : 'Add Word',
                          width: double.infinity,
                          onPressed: _save,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text, style: AppText.caption());

  Widget _field(TextEditingController ctrl, {String? hint}) {
    return TextField(
      controller: ctrl,
      style: AppText.body(),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.bg,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide:
              const BorderSide(color: AppColors.ink4, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide:
              const BorderSide(color: AppColors.green, width: 1.5),
        ),
        hintText: hint,
        hintStyle: AppText.body(color: AppColors.ink3),
      ),
    );
  }
}

// ─── Image area ───────────────────────────────────────────────────────────────

class _ImageArea extends StatelessWidget {
  const _ImageArea({
    required this.localImagePath,
    required this.imageUrl,
    required this.memoryBytes,
    required this.loading,
    required this.onPick,
    required this.onClear,
  });

  final String? localImagePath;
  final String? imageUrl;
  final Uint8List? memoryBytes;
  final bool loading;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.ink5,
          borderRadius: AppRadius.md,
        ),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
              color: AppColors.green, strokeWidth: 2.5),
        ),
      );
    }

    if (memoryBytes != null ||
        (localImagePath != null && localImagePath!.trim().isNotEmpty) ||
        (imageUrl != null && imageUrl!.trim().isNotEmpty)) {
      return Stack(
        children: [
          GestureDetector(
            onTap: onPick,
            child: VocabImage(
              localImagePath: localImagePath,
              imageUrl: imageUrl,
              memoryBytes: memoryBytes,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              borderRadius: AppRadius.md,
              placeholder: Container(
                width: 80,
                height: 80,
                color: AppColors.ink5,
              ),
              fallback: Container(
                width: 80,
                height: 80,
                color: AppColors.ink5,
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onClear,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.close_rounded,
                    size: 12, color: AppColors.ink),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onPick,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.bgRaised,
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.ink4, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_photo_alternate_rounded,
                size: 24, color: AppColors.ink3),
            const SizedBox(height: 4),
            Text('Upload',
                style: AppText.caption(color: AppColors.ink3)),
          ],
        ),
      ),
    );
  }
}

class _SelectedImage {
  const _SelectedImage({
    required this.name,
    required this.bytes,
  });

  final String name;
  final Uint8List bytes;
}
