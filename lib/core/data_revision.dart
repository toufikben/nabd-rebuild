import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bumped whenever the stored data changes underneath the running app, for
/// example after a backup restore. Screens that cache derived data watch this
/// so they refetch without needing the app to be restarted.
class DataRevision extends StateNotifier<int> {
  DataRevision() : super(0);

  void bump() => state = state + 1;
}

final dataRevisionProvider =
    StateNotifierProvider<DataRevision, int>((ref) => DataRevision());
