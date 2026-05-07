// data/sources/kanban_api_source.dart

import 'dart:convert';

import 'package:http/http.dart' as http;

import '/data/models/kanban_column.dart';
import '/data/models/kanban_task.dart';

class KanbanApiSource {
  static const _baseUrl = 'https://api.dev.kpi-drive.ru/_api/indicators';
  static const _token = 'Bearer 5c3964b8e3ee4755f2cc0febb851e2f8';
  static const _userId = '40';

  Map<String, String> get _headers => {'Authorization': _token};

  Future<List<KanbanColumn>> fetchBoard() async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/get_mo_indicators'),
    );

    request.headers.addAll(_headers);
    request.fields.addAll({
      'period_start': '2026-04-01',
      'period_end': '2026-04-30',
      'period_key': 'month',
      'requested_mo_id': '42',
      'behaviour_key': 'task,kpi_task',
      'with_result': 'false',
      'response_fields': 'name,indicator_to_mo_id,parent_id,order',
      'auth_user_id': _userId,
    });

    final streamedResponse = await request.send();
    final body = await streamedResponse.stream
        .bytesToString(); // ← must read stream first

    if (streamedResponse.statusCode != 200) {
      throw ApiException(streamedResponse.statusCode);
    }

    final jsonData = json.decode(body);
    final rows = jsonData['DATA']['rows'] as List<dynamic>;

    return _rowsToColumns(rows);
  }

  // Group flat rows into columns by parent_id, sorted by order
  List<KanbanColumn> _rowsToColumns(List<dynamic> rows) {
    final Map<String, List<KanbanTask>> grouped = {};

    for (final row in rows) {
      final parentId = row['parent_id']?.toString() ?? 'no_parent';
      final task = KanbanTask(
        id: row['indicator_to_mo_id'].toString(),
        title: row['name'] as String,
        order: int.tryParse(row['order']?.toString() ?? '0') ?? 0, // safe parse
      );
      grouped.putIfAbsent(parentId, () => []).add(task);
    }

    return grouped.entries.map((entry) {
      final sortedTasks = entry.value
        ..sort((a, b) => a.order.compareTo(b.order));
      return KanbanColumn(
        id: entry.key,
        title: 'Group ${entry.key}',
        tasks: sortedTasks,
      );
    }).toList();
  }

  Future<void> updateTaskField({
    required String indicatorToMoId,
    required String fieldName,
    required String fieldValue,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/save_indicator_instance_field'),
    );

    request.headers.addAll(_headers);
    request.fields.addAll({
      'period_start': '2026-04-01',
      'period_end': '2026-04-30',
      'period_key': 'month',
      'indicator_to_mo_id': indicatorToMoId,
      'field_name': fieldName,
      'field_value': fieldValue,
      'auth_user_id': _userId,
    });

    final response = await request.send();
    if (response.statusCode != 200) throw ApiException(response.statusCode);
  }

  // Moving to another column = updating parent_id
  Future<void> moveTask(String taskId, String toColumnId, int toIndex) async {
    await updateTaskField(
      indicatorToMoId: taskId,
      fieldName: 'parent_id',
      fieldValue: toColumnId,
    );
    await updateTaskField(
      indicatorToMoId: taskId,
      fieldName: 'order',
      fieldValue: toIndex.toString(),
    );
  }

  // Reordering = updating order only
  Future<void> reorderTask(String taskId, int newIndex) async {
    await updateTaskField(
      indicatorToMoId: taskId,
      fieldName: 'order',
      fieldValue: newIndex.toString(),
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  ApiException(this.statusCode);
}
