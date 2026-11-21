import 'package:flutter/foundation.dart';

/// Lets AppShell tell a tab that it was just selected, so the tab can reload
/// data that may have changed while it was in the background.
///
/// Pages listen to their own signal in initState and reload when it fires.
class TabRefresh {
  TabRefresh._();

  static final ValueNotifier<int> dashboard = ValueNotifier<int>(0);
  static final ValueNotifier<int> map = ValueNotifier<int>(0);

  /// Fires the signal for the tab at [index] (same numbering as AppShell).
  /// Tabs that don't reload on selection, like the create forms, are ignored.
  static void request(int index) {
    switch (index) {
      case 0:
        dashboard.value++;
      case 4:
        map.value++;
    }
  }
}