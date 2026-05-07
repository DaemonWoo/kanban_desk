// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kanban_task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KanbanTask _$KanbanTaskFromJson(Map<String, dynamic> json) => KanbanTask(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String? ?? '',
);

Map<String, dynamic> _$KanbanTaskToJson(KanbanTask instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
    };
