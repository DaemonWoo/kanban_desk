import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/data/models/kanban_column.dart';
import 'repository_providers.dart';

final kanbanProvider =
    AsyncNotifierProvider<KanbanNotifier, List<KanbanColumn>>(
      KanbanNotifier.new,
    );

final kanbanActionErrorProvider =
    NotifierProvider<KanbanActionErrorNotifier, KanbanActionError?>(
      KanbanActionErrorNotifier.new,
    );

class KanbanActionError {
  const KanbanActionError(this.message);
  final String message;
}

class KanbanActionErrorNotifier extends Notifier<KanbanActionError?> {
  @override
  KanbanActionError? build() => null;

  void show(String message) {
    state = KanbanActionError(message);
  }

  void clear() {
    state = null;
  }
}

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
    final current = state.value;
    if (current == null) return;

    // UI responds instantly
    final previous = state;
    state = AsyncData(
      _applyMove(current, taskId, fromColumnId, toColumnId, toIndex),
    );

    // Sync to API in background
    try {
      await ref
          .read(repositoryProvider)
          .moveTask(taskId, fromColumnId, toColumnId, toIndex);
    } catch (e) {
      state = previous; // rollback on failure
      ref.read(kanbanActionErrorProvider.notifier).show('Failed to move task');
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
    final current = state.value;
    if (current == null) return;

    final previous = state;
    state = AsyncData(_applyReorder(current, columnId, taskId, toIndex));
    try {
      await ref.read(repositoryProvider).reorderTask(taskId, toIndex);
    } catch (e) {
      state = previous;
      ref
          .read(kanbanActionErrorProvider.notifier)
          .show('Failed to reorder task');
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
    final oldIndex = col.tasks.indexWhere((t) => t.id == taskId);
    if (toIndex > oldIndex) toIndex--;
    final task = col.tasks.removeAt(oldIndex);
    col.tasks.insert(toIndex, task);
    return copy;
  }
}
