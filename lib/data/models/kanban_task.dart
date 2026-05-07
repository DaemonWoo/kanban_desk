import 'package:json_annotation/json_annotation.dart';

part 'kanban_task.g.dart';

@JsonSerializable()
class KanbanTask {
  KanbanTask({
    required this.id,
    required this.title,
    this.description = '',
    this.order = 0,
  });

  final String id;
  String title;
  String description;
  int order;

  factory KanbanTask.fromJson(Map<String, dynamic> json) =>
      _$KanbanTaskFromJson(json);
  Map<String, dynamic> toJson() => _$KanbanTaskToJson(this);
}
