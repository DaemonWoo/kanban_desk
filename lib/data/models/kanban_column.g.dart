// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kanban_column.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KanbanColumn _$KanbanColumnFromJson(Map<String, dynamic> json) => KanbanColumn(
  id: json['id'] as String,
  title: json['title'] as String,
  tasks: (json['tasks'] as List<dynamic>)
      .map((e) => KanbanTask.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$KanbanColumnToJson(KanbanColumn instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'tasks': instance.tasks,
    };
