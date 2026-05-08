import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class DragState {
  const DragState({required this.position, required this.activeColumnId});

  final Offset? position;
  final String? activeColumnId;

  DragState copyWith({
    Offset? position,
    bool clearPosition = false,
    String? activeColumnId,
    bool clearActiveColumnId = false,
  }) {
    return DragState(
      position: clearPosition ? null : (position ?? this.position),
      activeColumnId: clearActiveColumnId
          ? null
          : (activeColumnId ?? this.activeColumnId),
    );
  }
}

final dragPositionProvider = NotifierProvider<DragPositionNotifier, DragState>(
  DragPositionNotifier.new,
);

class DragPositionNotifier extends Notifier<DragState> {
  @override
  DragState build() => const DragState(position: null, activeColumnId: null);

  void updatePosition(Offset? position) {
    state = state.copyWith(position: position, clearPosition: position == null);
  }

  void setActiveColumn(String? columnId) {
    state = state.copyWith(
      activeColumnId: columnId,
      clearActiveColumnId: columnId == null,
    );
  }

  void clear() {
    state = const DragState(position: null, activeColumnId: null);
  }
}
