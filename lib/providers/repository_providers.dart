import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/data/data_sources/kanban_api_source.dart';
import '/data/repositories/kanban_repository.dart';

final apiSourceProvider = Provider<KanbanApiSource>((ref) => KanbanApiSource());

final repositoryProvider = Provider<KanbanRepository>(
  (ref) => KanbanRepository(api: ref.watch(apiSourceProvider)),
);
