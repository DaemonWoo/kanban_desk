import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/data/models/kanban_task.dart';
import '/providers/drag_provider.dart';
import '/theme/colors.dart';
import '/theme/text_styles.dart';

class KanbanCard extends ConsumerWidget {
  const KanbanCard({
    super.key,
    required this.task,
    required this.columnId,
    required this.width,
  });

  final KanbanTask task;
  final String columnId;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dragNotifier = ref.read(dragPositionProvider.notifier);

    return Draggable<Map<String, String>>(
      data: {'taskId': task.id, 'fromColumn': columnId},
      childWhenDragging: SizedBox(
        width: width,
        child: Opacity(opacity: 0.3, child: _cardContent()),
      ),
      onDragStarted: () {
        dragNotifier.setActiveColumn(columnId);
      },
      onDragUpdate: (details) {
        dragNotifier.updatePosition(details.globalPosition);
      },
      onDragEnd: (_) {
        dragNotifier.clear();
      },
      dragAnchorStrategy: _cardCenterDragAnchorStrategy,
      feedback: Material(
        elevation: 1,
        borderRadius: .circular(8),
        child: SizedBox(width: width, child: _cardContent()),
      ),
      rootOverlay: true,
      child: SizedBox(width: width, child: _cardContent()),
    );
  }

  Widget _cardContent() {
    return Card(
      margin: const .symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: .circular(8),
        side: const BorderSide(color: AppColors.cardBorder, width: 1),
      ),
      child: Padding(
        padding: const .all(12),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Text(task.title, style: AppTextStyles.taskText),
            if (task.description.isNotEmpty)
              Text(task.description, style: AppTextStyles.secondary),
          ],
        ),
      ),
    );
  }
}

Offset _cardCenterDragAnchorStrategy(
  Draggable<Object> draggable,
  BuildContext context,
  Offset position,
) {
  final renderObject = context.findRenderObject();
  if (renderObject is! RenderBox) return Offset.zero;
  return Offset(renderObject.size.width / 2, renderObject.size.height / 2);
}
