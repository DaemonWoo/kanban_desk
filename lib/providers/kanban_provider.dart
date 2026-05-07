import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/data/models/kanban_column.dart';
import 'repository_providers.dart';

final kanbanProvider =
    AsyncNotifierProvider<KanbanNotifier, List<KanbanColumn>>(
      KanbanNotifier.new,
    );

class KanbanNotifier extends AsyncNotifier<List<KanbanColumn>> {
  @override
  Future<List<KanbanColumn>> build() async {
    // Runs once on first watch and loads the board
    return ref.read(repositoryProvider).getBoard();
  }

  Future<void> moveTask(
    String taskId,
    String fromColumnId,
    String toColumnId,
    int toIndex,
  ) async {
    // UI responds instantly
    final previous = state;
    state = AsyncData(
      _applyMove(state.value!, taskId, fromColumnId, toColumnId, toIndex),
    );

    // Sync to API in background
    try {
      await ref
          .read(repositoryProvider)
          .moveTask(taskId, fromColumnId, toColumnId, toIndex);
    } catch (e) {
      print(e);
      state = previous; // rollback on failure
    }
  }

  List<KanbanColumn> _applyMove(
    List<KanbanColumn> cols,
    String taskId,
    String fromColumnId,
    String toColumnId,
    int toIndex,
  ) {
    final copy = cols
        .map((c) => KanbanColumn(id: c.id, title: c.title, tasks: [...c.tasks]))
        .toList();
    final from = copy.firstWhere((c) => c.id == fromColumnId);
    final to = copy.firstWhere((c) => c.id == toColumnId);
    final task = from.tasks.firstWhere((t) => t.id == taskId);
    from.tasks.remove(task);
    to.tasks.insert(toIndex.clamp(0, to.tasks.length), task);
    return copy;
  }

  Future<void> reorderTask(String columnId, String taskId, int toIndex) async {
    final previous = state;
    state = AsyncData(_applyReorder(state.value!, columnId, taskId, toIndex));
    try {
      await ref.read(repositoryProvider).reorderTask(taskId, toIndex);
    } catch (e) {
      state = previous;
    }
  }

  List<KanbanColumn> _applyReorder(
    List<KanbanColumn> cols,
    String columnId,
    String taskId,
    int toIndex,
  ) {
    final copy = cols
        .map((c) => KanbanColumn(id: c.id, title: c.title, tasks: [...c.tasks]))
        .toList();
    final col = copy.firstWhere((c) => c.id == columnId);
    final oldIndex = col.tasks.indexWhere(
      (t) => t.id == taskId,
    ); 
    if (toIndex > oldIndex) toIndex--;
    final task = col.tasks.removeAt(oldIndex);
    col.tasks.insert(toIndex, task);
    return copy;
  }
}
