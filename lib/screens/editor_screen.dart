import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../theme/vapor_theme.dart';
import '../widgets/water_animations.dart';

class EditorScreen extends StatefulWidget {
  final String noteId;

  const EditorScreen({super.key, required this.noteId});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen>
    with SingleTickerProviderStateMixin {
  Note? _note;
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _scrollController = ScrollController();
  final _newItemController = TextEditingController();

  late List<CheckItem> _checkItems;
  late List<NoteImage> _images;
  NoteType _noteType = NoteType.text;
  String _category = '未分类';
  int _colorIndex = 0;
  bool _isDirty = false;
  bool _isToolbarVisible = true;
  double _scrollOffset = 0;

  late SignatureController _signatureController;
  late TabController _tabController;

  final _picker = ImagePicker();
  final _uuid = const Uuid();

  static const List<String> _defaultCategories = [
    '未分类', '工作', '学习', '生活', '灵感', '待办'
  ];

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: VaporTheme.primary,
      exportBackgroundColor: Colors.white,
    );
    _tabController = TabController(length: 4, vsync: this);
    _loadNote();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final visible = offset < _scrollOffset + 10;
    _scrollOffset = offset;
    if (visible != _isToolbarVisible) {
      setState(() => _isToolbarVisible = visible);
    }
  }

  Future<void> _loadNote() async {
    final provider = context.read<NotesProvider>();
    final note = provider.allNotes.firstWhere(
      (n) => n.id == widget.noteId,
      orElse: () => Note(id: widget.noteId),
    );
    setState(() {
      _note = note;
      _titleController.text = note.title;
      _contentController.text = note.content;
      _checkItems = List.from(note.checkItems);
      _images = List.from(note.images);
      _noteType = note.type;
      _category = note.category;
      _colorIndex = note.colorIndex;
    });

    // Set tab based on note type
    switch (note.type) {
      case NoteType.checklist:
        _tabController.index = 1;
        break;
      case NoteType.doodle:
        _tabController.index = 2;
        break;
      default:
        _tabController.index = 0;
    }
  }

  Future<void> _save() async {
    if (_note == null) return;
    final updated = _note!.copyWith(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      type: _noteType,
      checkItems: _checkItems,
      images: _images,
      category: _category,
      colorIndex: _colorIndex,
    );
    await context.read<NotesProvider>().saveNote(updated);
    setState(() => _isDirty = false);
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  Future<void> _pickImage() async {
    final xFile = await _picker.pickImage(source: ImageSource.gallery);
    if (xFile == null) return;
    setState(() {
      _images.add(NoteImage(id: _uuid.v4(), path: xFile.path));
      _noteType = NoteType.mixed;
      _markDirty();
    });
  }

  void _addCheckItem() {
    final text = _newItemController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _checkItems.add(CheckItem(id: _uuid.v4(), text: text));
      _newItemController.clear();
      _noteType = NoteType.checklist;
      _markDirty();
    });
  }

  @override
  void dispose() {
    if (_isDirty) _save();
    _titleController.dispose();
    _contentController.dispose();
    _newItemController.dispose();
    _scrollController.dispose();
    _signatureController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = VaporTheme.cardColors[_colorIndex % VaporTheme.cardColors.length];

    return WillPopScope(
      onWillPop: () async {
        await _save();
        return true;
      },
      child: Scaffold(
        backgroundColor: VaporTheme.background,
        body: Column(
          children: [
            _buildAppBar(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTextEditor(cardBg),
                  _buildChecklistEditor(),
                  _buildDoodleEditor(),
                  _buildImageEditor(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomToolbar(),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
      ),
      decoration: BoxDecoration(
        color: VaporTheme.background.withOpacity(0.95),
        border: Border(
          bottom: BorderSide(color: VaporTheme.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () async {
              await _save();
              if (mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 20),
            color: VaporTheme.textPrimary,
          ),
          Expanded(
            child: TextField(
              controller: _titleController,
              onChanged: (_) => _markDirty(),
              decoration: const InputDecoration(
                hintText: '标题',
                hintStyle: TextStyle(
                  color: VaporTheme.textHint,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: VaporTheme.textPrimary,
              ),
            ),
          ),
          _buildCategoryChip(),
          IconButton(
            onPressed: _save,
            icon: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isDirty ? VaporTheme.primary : VaporTheme.surfaceBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '保存',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _isDirty ? Colors.white : VaporTheme.textHint,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: VaporTheme.background,
      child: TabBar(
        controller: _tabController,
        labelColor: VaporTheme.primary,
        unselectedLabelColor: VaporTheme.textHint,
        labelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        indicatorColor: VaporTheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorWeight: 2,
        onTap: (index) {
          NoteType type;
          switch (index) {
            case 1:
              type = NoteType.checklist;
              break;
            case 2:
              type = NoteType.doodle;
              break;
            case 3:
              type = NoteType.mixed;
              break;
            default:
              type = NoteType.text;
          }
          setState(() {
            _noteType = type;
            _markDirty();
          });
        },
        tabs: const [
          Tab(icon: Icon(Icons.notes_rounded, size: 18), text: '文字'),
          Tab(icon: Icon(Icons.checklist_rounded, size: 18), text: '清单'),
          Tab(icon: Icon(Icons.brush_rounded, size: 18), text: '涂鸦'),
          Tab(icon: Icon(Icons.image_rounded, size: 18), text: '图片'),
        ],
      ),
    );
  }

  Widget _buildTextEditor(Color bg) {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _contentController,
        onChanged: (_) => _markDirty(),
        maxLines: null,
        minLines: 20,
        decoration: const InputDecoration(
          hintText: '开始写作...',
          hintStyle: TextStyle(
            color: VaporTheme.textHint,
            fontSize: 15,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: EdgeInsets.zero,
        ),
        style: const TextStyle(
          fontSize: 15,
          color: VaporTheme.textPrimary,
          height: 1.8,
        ),
      ),
    );
  }

  Widget _buildChecklistEditor() {
    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: _checkItems.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _checkItems.removeAt(oldIndex);
                _checkItems.insert(newIndex, item);
                _markDirty();
              });
            },
            itemBuilder: (context, index) {
              final item = _checkItems[index];
              return _CheckItemTile(
                key: ValueKey(item.id),
                item: item,
                onToggle: (val) {
                  setState(() {
                    _checkItems[index] = CheckItem(
                      id: item.id,
                      text: item.text,
                      isChecked: val,
                    );
                    _markDirty();
                  });
                },
                onDelete: () {
                  setState(() {
                    _checkItems.removeAt(index);
                    _markDirty();
                  });
                },
                onChanged: (val) {
                  setState(() {
                    _checkItems[index] = CheckItem(
                      id: item.id,
                      text: val,
                      isChecked: item.isChecked,
                    );
                    _markDirty();
                  });
                },
              );
            },
          ),
        ),
        Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            top: 8,
          ),
          decoration: BoxDecoration(
            color: VaporTheme.background,
            border: Border(
              top: BorderSide(color: VaporTheme.divider, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.add_circle_outline_rounded,
                  color: VaporTheme.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _newItemController,
                  onSubmitted: (_) => _addCheckItem(),
                  decoration: const InputDecoration(
                    hintText: '添加待办事项...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(
                      fontSize: 15, color: VaporTheme.textPrimary),
                ),
              ),
              WaterRippleButton(
                onTap: _addCheckItem,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: VaporTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '添加',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDoodleEditor() {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: VaporTheme.divider),
                boxShadow: [
                  BoxShadow(
                    color: VaporTheme.primary.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Signature(
                  controller: _signatureController,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _DoodleToolButton(
                icon: Icons.color_lens_rounded,
                label: '颜色',
                onTap: () => _showColorPicker(),
              ),
              _DoodleToolButton(
                icon: Icons.undo_rounded,
                label: '撤销',
                onTap: () => _signatureController.undo(),
              ),
              _DoodleToolButton(
                icon: Icons.delete_outline_rounded,
                label: '清空',
                onTap: () => _signatureController.clear(),
              ),
              _DoodleToolButton(
                icon: Icons.save_alt_rounded,
                label: '保存',
                onTap: () async {
                  final data = await _signatureController.toPngBytes();
                  if (data != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('涂鸦已保存'),
                        backgroundColor: VaporTheme.primary,
                      ),
                    );
                    _markDirty();
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageEditor() {
    return Column(
      children: [
        Expanded(
          child: _images.isEmpty
              ? _buildImageEmpty()
              : GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    final img = _images[index];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            File(img.path),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) => Container(
                              color: VaporTheme.surfaceBlue,
                              child: const Icon(Icons.broken_image_rounded,
                                  color: VaporTheme.textHint),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: WaterRippleButton(
                            onTap: () {
                              setState(() {
                                _images.removeAt(index);
                                _markDirty();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            top: 8,
          ),
          child: WaterRippleButton(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: VaporTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: VaporTheme.primary.withOpacity(0.3),
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate_rounded,
                      color: VaporTheme.primary),
                  const SizedBox(width: 8),
                  const Text(
                    '添加图片',
                    style: TextStyle(
                      color: VaporTheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_outlined,
            size: 64,
            color: VaporTheme.textHint,
          ),
          const SizedBox(height: 12),
          const Text(
            '还没有图片',
            style: TextStyle(
              fontSize: 15,
              color: VaporTheme.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomToolbar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: _isToolbarVisible
          ? kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom
          : 0,
      child: Container(
        decoration: BoxDecoration(
          color: VaporTheme.background,
          border: Border(
            top: BorderSide(color: VaporTheme.divider, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            _ToolbarButton(
              icon: Icons.color_lens_outlined,
              onTap: _showCardColorPicker,
              tooltip: '卡片颜色',
            ),
            _ToolbarButton(
              icon: Icons.push_pin_outlined,
              onTap: () async {
                if (_note != null) {
                  await context
                      .read<NotesProvider>()
                      .togglePin(_note!.id);
                }
              },
              tooltip: '置顶',
            ),
            _ToolbarButton(
              icon: Icons.delete_outline_rounded,
              onTap: _deleteNote,
              tooltip: '删除',
              color: Colors.red.shade300,
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                _getWordCount(),
                style: const TextStyle(
                  fontSize: 12,
                  color: VaporTheme.textHint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip() {
    return GestureDetector(
      onTap: _showCategoryPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: VaporTheme.surfaceBlue,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_rounded,
                size: 13, color: VaporTheme.primary),
            const SizedBox(width: 4),
            Text(
              _category,
              style: const TextStyle(
                fontSize: 12,
                color: VaporTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getWordCount() {
    final total = _contentController.text.length +
        _checkItems.fold(0, (sum, i) => sum + i.text.length);
    return '$total 字';
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('选择分类',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _defaultCategories.map((cat) {
                final isSelected = _category == cat;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _category = cat;
                      _markDirty();
                    });
                    Navigator.pop(ctx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? VaporTheme.primary
                          : VaporTheme.surfaceBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : VaporTheme.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  void _showCardColorPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('卡片颜色',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(VaporTheme.cardColors.length, (i) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _colorIndex = i;
                      _markDirty();
                    });
                    Navigator.pop(ctx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: VaporTheme.cardColors[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: i == _colorIndex
                            ? VaporTheme.primary
                            : VaporTheme.cardBorderColors[i],
                        width: i == _colorIndex ? 3 : 1.5,
                      ),
                    ),
                    child: i == _colorIndex
                        ? const Icon(Icons.check, size: 16,
                            color: VaporTheme.primary)
                        : null,
                  ),
                );
              }),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  void _showColorPicker() {
    final colors = [
      VaporTheme.primary,
      VaporTheme.accent,
      Colors.indigo.shade400,
      Colors.purple.shade400,
      Colors.red.shade400,
      Colors.black87,
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('画笔颜色',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: colors.map((c) => GestureDetector(
                onTap: () {
                  _signatureController = SignatureController(
                    penStrokeWidth: 3,
                    penColor: c,
                    exportBackgroundColor: Colors.white,
                    points: _signatureController.points,
                  );
                  setState(() {});
                  Navigator.pop(ctx);
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                  ),
                ),
              )).toList(),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteNote() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('删除笔记'),
        content: const Text('确定删除此笔记？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消',
                style: TextStyle(color: VaporTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('删除',
                style: TextStyle(
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<NotesProvider>().deleteNote(widget.noteId);
      if (mounted) Navigator.pop(context);
    }
  }
}

class _CheckItemTile extends StatelessWidget {
  final CheckItem item;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final ValueChanged<String> onChanged;

  const _CheckItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SpringCheckbox(value: item.isChecked, onChanged: onToggle),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              initialValue: item.text,
              onChanged: onChanged,
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                fontSize: 15,
                color: item.isChecked
                    ? VaporTheme.textHint
                    : VaporTheme.textPrimary,
                decoration:
                    item.isChecked ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(
              Icons.remove_circle_outline_rounded,
              size: 18,
              color: Colors.red.shade300,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.drag_handle_rounded,
              size: 18, color: VaporTheme.textHint),
        ],
      ),
    );
  }
}

class _DoodleToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DoodleToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return WaterRippleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: VaporTheme.surfaceBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: VaporTheme.primary),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: VaporTheme.primary)),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color? color;

  const _ToolbarButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 22),
      color: color ?? VaporTheme.textSecondary,
      tooltip: tooltip,
    );
  }
}
