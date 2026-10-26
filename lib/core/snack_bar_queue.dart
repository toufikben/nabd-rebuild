import 'dart:async';

import 'package:flutter/material.dart';

/// The message asked for most recently; an older timer must never close it.
int _latest = 0;

/// Shows [snackBar] at once, replacing whatever is on screen, and closes it
/// after its own duration.
///
/// Flutter leaves a snack bar that carries an action on screen with no timer
/// while the platform reports accessible navigation, so the Undo offered after
/// a Replace could sit in front of the writer on the next screen for minutes.
/// Closing it here makes the duration mean what it says, and the latest-message
/// check keeps a stale timer from hiding a newer message.
void showSnackBarNow(ScaffoldMessengerState messenger, SnackBar snackBar) {
  final id = ++_latest;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(snackBar);
  unawaited(
    Future<void>.delayed(
      snackBar.duration + const Duration(milliseconds: 400),
      () {
        if (id == _latest && messenger.mounted) {
          messenger.hideCurrentSnackBar();
        }
      },
    ),
  );
}
