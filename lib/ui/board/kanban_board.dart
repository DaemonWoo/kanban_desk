import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/providers/drag_provider.dart';
import '/providers/kanban_provider.dart';
import 'kanban_column.dart';

class KanbanBoard extends ConsumerStatefulWidget {
  const KanbanBoard({super.key});

  @override
  ConsumerState<KanbanBoard> createState() => _KanbanBoardState();
}

class _KanbanBoardState extends ConsumerState<KanbanBoard>
    with TickerProviderStateMixin {
  final _scrollController = ScrollController();
  Ticker? _ticker;
  double _scrollDirection = 0;

  static const _edgeSize = 80.0;
  static const _scrollSpeed = 12.0;

  @override
  void dispose() {
    _ticker?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
    final boardAsync = ref.watch(kanbanProvider);

    ref.listen(kanbanActionErrorProvider, (_, error) {
      if (error == null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error.message),
            behavior: .floating,
            duration: const Duration(seconds: 2),
          ),
        );
      ref.read(kanbanActionErrorProvider.notifier).clear();
    });

    ref.listen(dragPositionProvider, (_, dragState) {
      final position = dragState.position;
      if (position == null) {
        _stopScrolling();
        return;
      }
      final screenWidth = MediaQuery.of(context).size.width;
      if (position.dx < _edgeSize) {
        _startScrolling(-_scrollSpeed);
      } else if (position.dx > screenWidth - _edgeSize) {
        _startScrolling(_scrollSpeed);
      } else {
        _stopScrolling();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Kanban')),
      body: boardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (columns) => Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          trackVisibility: true,
          interactive: true,
          scrollbarOrientation: .bottom,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: .horizontal,
            physics: const ClampingScrollPhysics(),
            child: SizedBox(
              height:
                  MediaQuery.of(context).size.height -
                  kToolbarHeight -
                  MediaQuery.of(context).padding.top,
              child: Padding(
                padding: const .only(bottom: 12),
                child: Row(
                  crossAxisAlignment: .start,
                  children: columns
                      .map(
                        (col) => KanbanColumnWidget(
                          key: ValueKey(col.id),
                          column: col,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
