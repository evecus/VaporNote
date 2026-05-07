import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notes_provider.dart';
import '../theme/vapor_theme.dart';

class VaporDrawer extends StatelessWidget {
  const VaporDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotesProvider>();

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  VaporTheme.primary,
                  VaporTheme.primaryDark,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(32),
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              left: 24,
              right: 24,
              bottom: 28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.water_drop_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'VaporNote',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${provider.allNotes.length} 条笔记',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // All notes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _CategoryTile(
              icon: Icons.grid_view_rounded,
              label: '全部笔记',
              count: provider.allNotes.length,
              isSelected: provider.currentCategory == '全部',
              onTap: () {
                provider.setCategory('全部');
                Navigator.pop(context);
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  '我的分类',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: VaporTheme.textHint,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: provider.categories
                  .where((c) => c != '全部')
                  .length,
              itemBuilder: (context, index) {
                final cats =
                    provider.categories.where((c) => c != '全部').toList();
                final cat = cats[index];
                final count =
                    provider.allNotes.where((n) => n.category == cat).length;
                return _CategoryTile(
                  icon: Icons.folder_rounded,
                  label: cat,
                  count: count,
                  isSelected: provider.currentCategory == cat,
                  onTap: () {
                    provider.setCategory(cat);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),

          const Divider(color: VaporTheme.divider, height: 1),
          const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            child: _CategoryTile(
              icon: Icons.settings_rounded,
              label: '设置',
              isSelected: false,
              onTap: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? count;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.icon,
    required this.label,
    this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? VaporTheme.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(
          icon,
          size: 20,
          color: isSelected ? VaporTheme.primary : VaporTheme.textSecondary,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? VaporTheme.primary : VaporTheme.textPrimary,
          ),
        ),
        trailing: count != null
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? VaporTheme.primary
                      : VaporTheme.divider,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : VaporTheme.textHint,
                  ),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
