import '/data/models/kanban_column.dart';
import '/data/models/kanban_task.dart';
import '/data/models/tree_row_dto.dart';

List<KanbanColumn> mapTreeRowsToColumns(List<TreeRowDto> rows) {
  if (rows.isEmpty) {
    return const [];
  }

  final rowsById = <String, TreeRowDto>{for (final row in rows) row.id: row};
  final childrenByParent = <String, List<TreeRowDto>>{};

  for (final row in rows) {
    childrenByParent.putIfAbsent(row.parentId, () => []).add(row);
  }

  for (final children in childrenByParent.values) {
    children.sort((a, b) => a.order.compareTo(b.order));
  }

  final parentIds = childrenByParent.keys.toSet();
  final leafIds = rowsById.keys.where((id) => !parentIds.contains(id)).toSet();

  final columns = <KanbanColumn>[];
  for (final entry in childrenByParent.entries) {
    final parentId = entry.key;
    final children = entry.value;
    final title =
        rowsById[parentId]?.name ??
        children.first.parentName ??
        'Group $parentId';

    final tasks = children
        .where((row) => leafIds.contains(row.id))
        .map((row) => KanbanTask(id: row.id, title: row.name, order: row.order))
        .toList();

    columns.add(KanbanColumn(id: parentId, title: title, tasks: tasks));
  }

  return columns;
}
