import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/theme/text_styles.dart';

import '/data/models/kanban_column.dart';
import '/providers/drag_provider.dart';
import '/providers/kanban_provider.dart';
import '/theme/colors.dart';
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
  String? _draggingTaskId;
  String? _draggingFromColumnId;
  final _scrollController = ScrollController();
  final _columnKey = GlobalKey();
  Ticker? _ticker;
  double _scrollDirection = 0;
  static const _edgeSize = 60.0;
  static const _scrollSpeed = 8.0;
  static const _columnWidth = 260.0;
  static const _columnRadius = 12.0;
  static const _columnBorderWidth = 2.0;
  static const _columnHeaderHeight = 52.0;

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

  void _setDraggingOver(bool value) {
    setState(() {
      _isDraggingOver = value;
      if (!value) {
        _hoveredIndex = null;
      }
    });
  }

  void _clearDragVisualState() {
    _stopScrolling();
    setState(() {
      _isDraggingOver = false;
      _hoveredIndex = null;
      _draggingTaskId = null;
      _draggingFromColumnId = null;
    });
  }

  void _captureDragMeta(Map<String, String>? data) {
    _draggingTaskId = data?['taskId'];
    _draggingFromColumnId = data?['fromColumn'];
  }

  int _resolveTargetIndex(Offset? pointerGlobalPosition) {
    if (widget.column.tasks.isEmpty) return 1;
    if (pointerGlobalPosition == null) {
      return _hoveredIndex ?? widget.column.tasks.length;
    }

    for (var i = 0; i < widget.column.tasks.length; i++) {
      final taskId = widget.column.tasks[i].id;
      final renderBox =
          _cardKeys[taskId]?.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) continue;

      final top = renderBox.localToGlobal(Offset.zero).dy;
      final middle = top + renderBox.size.height / 2;
      if (pointerGlobalPosition.dy < middle) {
        return i;
      }
    }

    return widget.column.tasks.length;
  }

  bool _isNoOpTarget(int index) {
    if (_draggingFromColumnId != widget.column.id || _draggingTaskId == null) {
      return false;
    }

    final oldIndex = widget.column.tasks.indexWhere(
      (t) => t.id == _draggingTaskId,
    );
    if (oldIndex < 0) return false;

    // For same-column drag, dropping right before or right after itself changes
    // nothing.
    return index == oldIndex || index == oldIndex + 1;
  }

  final Map<String, GlobalKey> _cardKeys = {};

  GlobalKey _keyForTask(String taskId) {
    return _cardKeys.putIfAbsent(taskId, () => GlobalKey(debugLabel: taskId));
  }

  BoxDecoration _buildColumnDecoration(bool isDraggingOver) {
    return BoxDecoration(
      color: isDraggingOver
          ? AppColors.accentSubtle
          : AppColors.columnBackground,
      borderRadius: .circular(_columnRadius),
      border: .all(
        color: isDraggingOver ? AppColors.accent : AppColors.columnBorder,
        width: _columnBorderWidth,
      ),
    );
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
      onWillAcceptWithDetails: (details) {
        ref
            .read(dragPositionProvider.notifier)
            .setActiveColumn(widget.column.id);
        _captureDragMeta(details.data);
        final pointerPosition =
            ref.read(dragPositionProvider).position ?? details.offset;
        final resolvedIndex = _resolveTargetIndex(pointerPosition);
        setState(() {
          _isDraggingOver = true;
          _hoveredIndex = resolvedIndex;
        });
        return true;
      },
      onMove: (details) {
        final dragNotifier = ref.read(dragPositionProvider.notifier);
        dragNotifier.setActiveColumn(widget.column.id);
        _captureDragMeta(details.data);
        final pointerPosition =
            ref.read(dragPositionProvider).position ?? details.offset;
        final resolvedIndex = _resolveTargetIndex(pointerPosition);
        if (!_isDraggingOver) {
          _setDraggingOver(true);
        }
        if (_hoveredIndex != resolvedIndex) {
          setState(() => _hoveredIndex = resolvedIndex);
        }
      },
      onLeave: (_) {
        final dragNotifier = ref.read(dragPositionProvider.notifier);
        final currentDragState = ref.read(dragPositionProvider);
        if (currentDragState.activeColumnId == widget.column.id) {
          dragNotifier.setActiveColumn(null);
        }
        _clearDragVisualState();
      },
      onAcceptWithDetails: (details) {
        final taskId = details.data['taskId']!;
        final fromCol = details.data['fromColumn']!;
        final pointerPosition =
            ref.read(dragPositionProvider).position ?? details.offset;
        final toIndex = _resolveTargetIndex(pointerPosition);

        if (fromCol == widget.column.id && _isNoOpTarget(toIndex)) {
          _clearDragVisualState();
          return;
        }

        if (fromCol == widget.column.id) {
          ref
              .read(kanbanProvider.notifier)
              .reorderTask(widget.column.id, taskId, toIndex);
        } else {
          ref
              .read(kanbanProvider.notifier)
              .moveTask(taskId, fromCol, widget.column.id, toIndex);
        }
        _clearDragVisualState();
      },
      builder: (context, _, _) {
        return Container(
          key: _columnKey,
          width: _columnWidth,
          height: double.infinity,
          margin: const .all(8),
          decoration: _buildColumnDecoration(_isDraggingOver),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: const .vertical(top: .circular(_columnRadius)),
                  color: AppColors.columnHeader,
                ),
                height: _columnHeaderHeight,
                width: .infinity,
                alignment: .center,
                padding: const .symmetric(horizontal: 12),
                child: Text(
                  widget.column.title,
                  style: AppTextStyles.columnTitle,
                  maxLines: 1,
                  overflow: .ellipsis,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const .symmetric(vertical: 12),
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
    final isTarget =
        _isDraggingOver && _hoveredIndex == index && !_isNoOpTarget(index);
    final placeholderTopPadding = isTarget && index == 0 ? 8.0 : 0.0;
    final indicatorAnimationDuration = _isDraggingOver
        ? const Duration(milliseconds: 120)
        : Duration.zero;
    return MouseRegion(
      onEnter: (_) {
        if (_isDraggingOver) setState(() => _hoveredIndex = index);
      },
      child: Padding(
        padding: EdgeInsets.only(top: placeholderTopPadding),
        child: AnimatedContainer(
          duration: indicatorAnimationDuration,
          curve: Curves.easeOutCubic,
          height: isTarget ? 48 : 6,
          margin: const .symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isTarget ? AppColors.accentSoft : AppColors.transparent,
            borderRadius: .circular(8),
            border: isTarget ? .all(color: AppColors.accent) : null,
          ),
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
      child: KanbanCard(
        key: _keyForTask(task.id),
        task: task,
        columnId: widget.column.id,
        width: _columnWidth,
      ),
    );
  }
}
