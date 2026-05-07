import 'package:json_annotation/json_annotation.dart';

import 'kanban_task.dart';

part 'kanban_column.g.dart';       

@JsonSerializable()
class KanbanColumn {
  KanbanColumn({required this.id, required this.title, required this.tasks});

  final String id;
  String title;
  List<KanbanTask> tasks;
  
factory KanbanColumn.fromJson(Map<String, dynamic> json) =>
      _$KanbanColumnFromJson(json);
  Map<String, dynamic> toJson() => _$KanbanColumnToJson(this);
}
