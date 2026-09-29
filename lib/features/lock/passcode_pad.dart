import 'package:flutter/material.dart';

/// Numeric pad used to enter the app passcode.
class PasscodePad extends StatelessWidget {
  const PasscodePad({
    super.key,
    required this.onSubmit,
    this.locked = false,
    this.remainingSeconds = 0,
    this.onForgotTap,
  });

  final ValueChanged<String> onSubmit;
  final bool locked;
  final int remainingSeconds;
  final VoidCallback? onForgotTap;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
