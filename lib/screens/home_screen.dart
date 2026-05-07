import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../providers/notes_provider.dart';
import '../theme/vapor_theme.dart';
import '../widgets/note_card.dart';
import '../widgets/vapor_drawer.dart';
import 'editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  double _appBarOpacity = 1.0;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotesProvider>().loadNotes();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final opacity = (1.0 - (offset / 80)).clamp(0.0, 1.0);
    if ((opacity - _appBarOpacity).abs() > 0.01) {
      setState(() => _appBarOpacity = opacity);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotesProvider>();
    final isSelection = provider.isSelectionMode;

    return Scaffold(
      backgroundColor: VaporTheme.background,
      drawer: const VaporDrawer(),
      body: Stack(
        children: [
          // Subtle background decoration
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VaporTheme.primary.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VaporTheme.accent.withOpacity(0.04),
              ),
            ),
          ),

          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                expandedHeight: 120,
                pinned: true,
                stretch: true,
                leading: Builder(
                  builder: (ctx) => IconButton(
                    onPressed: isSelection
                        ? () => provider.clearSelection()
                        : () => Scaffold.of(ctx).openDrawer(),
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: isSelection
                          ? const Icon(Icons.close_rounded,
                              key: ValueKey('close'))
                          : const Icon(Icons.menu_rounded,
                              key: ValueKey('menu')),
                    ),
                    color: VaporTheme.textPrimary,
                  ),
                ),
                actions: [
                  if (isSelection) ...[
                    IconButton(
                      onPressed: () => _deleteSelected(context, provider),
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: Colors.red.shade400,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Center(
                        child: Text(
                          '已选 ${provider.selectedIds.length}',
                          style: const TextStyle(
                            color: VaporTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    IconButton(
                      onPressed: () => setState(() => _isSearching = !_isSearching),
                      icon: const Icon(Icons.search_rounded),
                      color: VaporTheme.textPrimary,
                    ),
                  ],
                ],
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: AnimatedOpacity(
                    opacity: _appBarOpacity,
                    duration: const Duration(milliseconds: 100),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VaporNote',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: VaporTheme.textPrimary,
                            letterSpacing: -0.8,
                          ),
                        ),
                        Text(
                          provider.currentCategory == '全部'
                              ? '${provider.allNotes.length} 条笔记'
                              : provider.currentCategory,
                          style: const TextStyle(
                            fontSize: 13,
                            color: VaporTheme.textHint,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          VaporTheme.background,
                          VaporTheme.background.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Search bar
              if (_isSearching)
                SliverToBoxAdapter(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: provider.setSearchQuery,
                      decoration: InputDecoration(
                        hintText: '搜索笔记...',
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: VaporTheme.textHint),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  provider.setSearchQuery('');
                                },
                                icon: const Icon(Icons.close_rounded,
                                    color: VaporTheme.textHint),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),

              // Notes grid
              if (provider.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: VaporTheme.primary,
                      strokeWidth: 2,
                    ),
                  ),
                )
              else if (provider.notes.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final note = provider.notes[index];
                        return AnimationConfiguration.staggeredGrid(
                          position: index,
                          duration: const Duration(milliseconds: 400),
                          columnCount: 2,
                          child: SlideAnimation(
                            verticalOffset: 40,
                            child: FadeInAnimation(
                              child: NoteCard(
                                note: note,
                                isSelected:
                                    provider.selectedIds.contains(note.id),
                                onTap: () {
                                  if (provider.isSelectionMode) {
                                    provider.toggleSelection(note.id);
                                  } else {
                                    _openNote(context, note.id);
                                  }
                                },
                                onLongPress: () {
                                  provider.startSelection(note.id);
                                },
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: provider.notes.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: AnimatedScale(
        scale: isSelection ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: FloatingActionButton.extended(
          onPressed: () => _createNote(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            '新建',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: VaporTheme.primary,
          foregroundColor: Colors.white,
          elevation: 6,
          extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: VaporTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.water_drop_outlined,
              size: 40,
              color: VaporTheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '还没有笔记',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: VaporTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击 + 新建 开始记录',
            style: TextStyle(
              fontSize: 14,
              color: VaporTheme.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createNote(BuildContext context) async {
    final provider = context.read<NotesProvider>();
    final note = await provider.createNote(
      category: provider.currentCategory,
    );
    if (!mounted) return;
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => EditorScreen(noteId: note.id),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
    provider.loadNotes();
  }

  Future<void> _openNote(BuildContext context, String id) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => EditorScreen(noteId: id),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
    if (mounted) context.read<NotesProvider>().loadNotes();
  }

  Future<void> _deleteSelected(
      BuildContext context, NotesProvider provider) async {
    final count = provider.selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('删除笔记'),
        content: Text('确定删除 $count 条笔记？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('取消',
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
    if (confirm == true) provider.deleteSelected();
  }
}
