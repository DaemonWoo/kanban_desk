import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/data/models/kanban_column.dart';
import '/providers/drag_provider.dart';
import '/providers/kanban_provider.dart';
import 'kanban_card.dart';

class KanbanColumnWidget extends ConsumerStatefulWidget {
  const KanbanColumnWidget({super.key, required this.column});

  final KanbanColumn column;

  @override
  ConsumerState<KanbanColumnWidget> createState() => _KanbanColumnWidgetState();
}

class _KanbanColumnWidgetState extends ConsumerState<KanbanColumnWidget>
    with TickerProviderStateMixin {
  int? _hoveredIndex; // which gap is highlighted
  bool _isDraggingOver = false;
  final _scrollController = ScrollController();
  final _columnKey = GlobalKey();
  Ticker? _ticker;
  double _scrollDirection = 0;
  static const _edgeSize = 60.0;
  static const _scrollSpeed = 6.0;

  void _startScrolling(double direction) {
    if (_ticker != null) {
      _scrollDirection = direction;
      return;
    }
    _scrollDirection = direction;
    _ticker = createTicker((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(
        (_scrollController.offset + _scrollDirection).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        ),
      );
    })..start();
  }

  void _stopScrolling() {
    _ticker?.dispose();
    _ticker = null;
    _scrollDirection = 0;
  }

  @override
  void dispose() {
    _stopScrolling();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(dragPositionProvider, (_, dragState) {
      final position = dragState.position;
      final isActiveColumn = dragState.activeColumnId == widget.column.id;
      if (position == null || !isActiveColumn) {
        _stopScrolling();
        return;
      }

      final box = _columnKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) return;
      final topLeft = box.localToGlobal(Offset.zero);
      final columnLeft = topLeft.dx;
      final columnTop = topLeft.dy;
      final columnRight = columnLeft + box.size.width;
      final columnBottom = columnTop + box.size.height;

      if (position.dx < columnLeft || position.dx > columnRight) {
        _stopScrolling();
        return;
      }

      if (position.dy < columnTop + _edgeSize) {
        _startScrolling(-_scrollSpeed);
      } else if (position.dy > columnBottom - _edgeSize) {
        _startScrolling(_scrollSpeed);
      } else {
        _stopScrolling();
      }
    });

    return DragTarget<Map<String, String>>(
      onWillAcceptWithDetails: (_) {
        ref
            .read(dragPositionProvider.notifier)
            .setActiveColumn(widget.column.id);
        setState(() {
          _isDraggingOver = true; // SET ON DRAG ENTER
          _hoveredIndex = widget.column.tasks.length;
        });
        return true;
      },
      onMove: (details) {
        final dragNotifier = ref.read(dragPositionProvider.notifier);
        dragNotifier.setActiveColumn(widget.column.id);
        dragNotifier.updatePosition(details.offset);
      },
      onLeave: (_) {
        final dragNotifier = ref.read(dragPositionProvider.notifier);
        final currentDragState = ref.read(dragPositionProvider);
        if (currentDragState.activeColumnId == widget.column.id) {
          dragNotifier.setActiveColumn(null);
        }
        _stopScrolling();
        setState(() {
          _isDraggingOver = false; // CLEAR ON DRAG LEAVE
          _hoveredIndex = null;
        });
      },
      onAcceptWithDetails: (details) {
        final taskId = details.data['taskId']!;
        final fromCol = details.data['fromColumn']!;
        final toIndex = _hoveredIndex ?? widget.column.tasks.length;

        if (fromCol == widget.column.id) {
          ref
              .read(kanbanProvider.notifier)
              .reorderTask(widget.column.id, taskId, toIndex);
        } else {
          ref
              .read(kanbanProvider.notifier)
              .moveTask(taskId, fromCol, widget.column.id, toIndex);
        }
        _stopScrolling();
        setState(() {
          _isDraggingOver = false; // CLEAR ON DROP
          _hoveredIndex = null;
        });
      },
      builder: (context, candidateData, _) {
        final isDraggingOver = candidateData.isNotEmpty;

        return Container(
          key: _columnKey,
          width: 260,
          height: double.infinity,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDraggingOver
                ? Colors.blue.withOpacity(0.05)
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: isDraggingOver
                ? Border.all(color: Colors.blue.withOpacity(0.4), width: 2)
                : null,
          ),
          child: Column(
            children: [
              Padding(
                padding: const .all(12),
                child: Text(
                  widget.column.title,
                  style: const TextStyle(fontWeight: .bold, fontSize: 16),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: widget.column.tasks.length + 1,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        _buildDropIndicator(index),
                        if (index < widget.column.tasks.length)
                          _buildDraggableCard(context, index),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Highlight the gap the card will land in
  Widget _buildDropIndicator(int index) {
    final isTarget = _isDraggingOver && _hoveredIndex == index;
    return MouseRegion(
      onEnter: (_) {
        if (_isDraggingOver) setState(() => _hoveredIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: isTarget ? 48 : 6,
        margin: const .symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isTarget ? Colors.blue.withOpacity(0.25) : Colors.transparent,
          borderRadius: .circular(8),
          border: isTarget ? .all(color: Colors.blue, width: 1.5) : null,
        ),
      ),
    );
  }

  Widget _buildDraggableCard(BuildContext context, int index) {
    final task = widget.column.tasks[index];
    return MouseRegion(
      onEnter: (_) {
        if (_isDraggingOver) {
          setState(() => _hoveredIndex = index + 1);
        }
      },
      child: KanbanCard(task: task, columnId: widget.column.id),
    );
  }
}
