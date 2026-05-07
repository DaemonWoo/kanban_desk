import 'package:last_kanban/data/data_sources/kanban_api_source.dart';

import '/data/models/kanban_column.dart';
import '/data/models/kanban_task.dart';

class KanbanRepository {
  final KanbanApiSource _api;
  // final KanbanLocalSource _local; // add Drift later

  KanbanRepository({required KanbanApiSource api}) : _api = api;

  Future<List<KanbanColumn>> getBoard() async {
    //return dummyData;
    // Later: try local first, then remote
    return await _api.fetchBoard();
  }

  Future<void> moveTask(
    String taskId,
    String fromColumnId,
    String toColumnId,
    int toIndex,
  ) async {
    // Later: update local immediately, then sync to remote
    await _api.moveTask(taskId, toColumnId, toIndex);
  }

  Future<void> reorderTask(String columnId, int newIndex) =>
      _api.reorderTask(columnId, newIndex);
}

final dummyData = [
  KanbanColumn(
    id: 'todo',
    title: 'To Do',
    tasks: [KanbanTask(id: '1', title: 'first')],
  ),
  KanbanColumn(
    id: 'doing',
    title: 'In Progress',
    tasks: [
      KanbanTask(id: '2', title: 'second'),
      KanbanTask(id: '4', title: 'forth'),
    ],
  ),
  KanbanColumn(
    id: 'done',
    title: 'Done',
    tasks: [KanbanTask(id: '2', title: 'third')],
  ),
];
