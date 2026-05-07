import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../theme/vapor_theme.dart';
import 'water_animations.dart';

class NoteCard extends StatefulWidget {
  final Note note;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const NoteCard({
    super.key,
    required this.note,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> with SingleTickerProviderStateMixin {
  late AnimationController _selectController;
  late Animation<double> _selectAnim;

  @override
  void initState() {
    super.initState();
    _selectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _selectAnim = CurvedAnimation(
      parent: _selectController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void didUpdateWidget(NoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _selectController.forward(from: 0);
      } else {
        _selectController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _selectController.dispose();
    super.dispose();
  }

  Color get cardColor => VaporTheme.cardColors[
      widget.note.colorIndex % VaporTheme.cardColors.length];

  Color get borderColor => VaporTheme.cardBorderColors[
      widget.note.colorIndex % VaporTheme.cardBorderColors.length];

  @override
  Widget build(BuildContext context) {
    return WaterRippleButton(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedBuilder(
        animation: _selectAnim,
        builder: (context, child) => Transform.scale(
          scale: widget.isSelected ? 0.95 : 1.0,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? VaporTheme.primaryLight.withOpacity(0.2)
                : cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSelected ? VaporTheme.primary : borderColor,
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: VaporTheme.primary.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [
                    BoxShadow(
                      color: VaporTheme.primary.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.note.isPinned)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.push_pin_rounded,
                              size: 12,
                              color: VaporTheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '置顶',
                              style: TextStyle(
                                fontSize: 11,
                                color: VaporTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (widget.note.title.isNotEmpty) ...[
                      Text(
                        widget.note.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: VaporTheme.textPrimary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                    ],
                    _buildPreview(),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildTypeChip(),
                        const Spacer(),
                        Text(
                          _formatDate(widget.note.updatedAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: VaporTheme.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (widget.isSelected)
                Positioned(
                  top: 10,
                  right: 10,
                  child: ScaleTransition(
                    scale: _selectAnim,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: VaporTheme.primary,
                      ),
                      child: const Icon(Icons.check, size: 14, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (widget.note.type == NoteType.checklist && widget.note.checkItems.isNotEmpty) {
      final items = widget.note.checkItems.take(3).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      Icon(
                        item.isChecked
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
                        size: 13,
                        color: item.isChecked
                            ? VaporTheme.primary
                            : VaporTheme.textHint,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          item.text,
                          style: TextStyle(
                            fontSize: 13,
                            color: item.isChecked
                                ? VaporTheme.textHint
                                : VaporTheme.textSecondary,
                            decoration: item.isChecked
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      );
    }

    if (widget.note.content.isNotEmpty) {
      return Text(
        widget.note.content,
        style: const TextStyle(
          fontSize: 13,
          color: VaporTheme.textSecondary,
          height: 1.5,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      );
    }

    if (widget.note.doodlePath != null) {
      return Row(
        children: [
          Icon(Icons.brush_rounded, size: 14, color: VaporTheme.textHint),
          const SizedBox(width: 4),
          Text('涂鸦笔记', style: TextStyle(fontSize: 13, color: VaporTheme.textHint)),
        ],
      );
    }

    return Text(
      '无内容',
      style: TextStyle(fontSize: 13, color: VaporTheme.textHint, fontStyle: FontStyle.italic),
    );
  }

  Widget _buildTypeChip() {
    IconData icon;
    String label;
    switch (widget.note.type) {
      case NoteType.checklist:
        icon = Icons.checklist_rounded;
        label = '清单';
        break;
      case NoteType.doodle:
        icon = Icons.brush_rounded;
        label = '涂鸦';
        break;
      case NoteType.mixed:
        icon = Icons.auto_awesome_rounded;
        label = '混合';
        break;
      default:
        icon = Icons.notes_rounded;
        label = '文字';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: VaporTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: VaporTheme.primary),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: VaporTheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return DateFormat('MM/dd').format(date);
  }
}
