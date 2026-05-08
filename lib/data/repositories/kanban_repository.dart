import '/data/data_sources/kanban_api_source.dart';
import '/data/mappers/kanban_tree_mapper.dart';
import '/data/models/kanban_column.dart';

class KanbanRepository {
  final KanbanApiSource _api;

  KanbanRepository({required KanbanApiSource api}) : _api = api;

  Future<List<KanbanColumn>> getBoard() async {
    final rows = await _api.fetchBoardRows();
    return mapTreeRowsToColumns(rows);
  }

  Future<void> moveTask(
    String taskId,
    String fromColumnId,
    String toColumnId,
    int toIndex,
  ) async {
    await _api.moveTask(taskId, toColumnId, toIndex);
  }

  Future<void> reorderTask(String columnId, int newIndex) =>
      _api.reorderTask(columnId, newIndex);
}
