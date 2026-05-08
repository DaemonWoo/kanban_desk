import 'dart:convert';

import 'package:http/http.dart' as http;

import '/data/models/tree_row_dto.dart';

class KanbanApiSource {
  static const _baseUrl = 'https://api.dev.kpi-drive.ru/_api/indicators';
  static const _token = 'Bearer 5c3964b8e3ee4755f2cc0febb851e2f8';
  static const _userId = '40';

  Map<String, String> get _headers => {'Authorization': _token};

  Future<List<TreeRowDto>> fetchBoardRows() async {
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
      'response_fields': 'name,indicator_to_mo_id,parent_id,order,parent_name',
      'auth_user_id': _userId,
    });

    final streamedResponse = await request.send();
    if (streamedResponse.statusCode != 200) {
      throw ApiException(streamedResponse.statusCode);
    }

    final body = await streamedResponse.stream.bytesToString();

    final jsonData = json.decode(body);
    final rows = jsonData['DATA']['rows'] as List<dynamic>;

    return rows
        .whereType<Map<String, dynamic>>()
        .map(TreeRowDto.fromJson)
        .toList();
  }

  Future<void> _batchUpdateFields(
    String taskId,
    Map<String, String> fields,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/save_indicator_instance_field'),
    );

    request.headers.addAll(_headers);
    request.fields.addAll({
      'period_start': '2026-04-01',
      'period_end': '2026-04-30',
      'period_key': 'month',
      'indicator_to_mo_id': taskId,
      'auth_user_id': _userId,
    });

    // Add each field name/value pair
    for (final entry in fields.entries) {
      request.files.add(http.MultipartFile.fromString('field_name', entry.key));
      request.files.add(
        http.MultipartFile.fromString('field_value', entry.value),
      );
    }

    final response = await request.send();
    if (response.statusCode != 200) throw ApiException(response.statusCode);
  }

  // Moving to another column = update parent_id and order
  Future<void> moveTask(String taskId, String toColumnId, int toIndex) =>
      _batchUpdateFields(taskId, {
        'parent_id': toColumnId,
        'order': toIndex.toString(),
      });

  // Reordering = update order only
  Future<void> reorderTask(String taskId, int newIndex) =>
      _batchUpdateFields(taskId, {
        // API expects zero-based order.
        'order': newIndex.toString(),
      });
}

class ApiException implements Exception {
  final int statusCode;
  ApiException(this.statusCode);
}
