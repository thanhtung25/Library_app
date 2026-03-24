import 'package:flutter/foundation.dart';

class FavoriteManager {
  FavoriteManager._();

  static final ValueNotifier<Set<int>> _notifier =
  ValueNotifier<Set<int>>({});

  static ValueNotifier<Set<int>> get notifier => _notifier;

  static bool isFavorite(int id) => _notifier.value.contains(id);

  static void toggle(int id) {
    final updated = Set<int>.from(_notifier.value);
    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.add(id);
    }
    _notifier.value = updated;
  }
}
