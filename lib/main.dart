import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/ui/board/kanban_board.dart';

void main() {
  runApp(const ProviderScope(child: MaterialApp(home: KanbanBoard())));
}


