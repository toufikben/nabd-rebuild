import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/database_service.dart';

/// Bumped whenever the stored data changes underneath the running app, for
/// example after a backup restore. Screens that cache derived data watch this
/// so they refetch without needing the app to be restarted.
class DataRevision extends StateNotifier<int> {
  DataRevision() : super(0) {
    // Any entry written, edited or deleted, from any screen.
    DatabaseService.changes.addListener(bump);
  }

  void bump() {
    if (mounted) state = state + 1;
  }

  @override
  void dispose() {
    DatabaseService.changes.removeListener(bump);
    super.dispose();
  }
}

final dataRevisionProvider =
    StateNotifierProvider<DataRevision, int>((ref) => DataRevision());
