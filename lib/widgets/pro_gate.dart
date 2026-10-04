import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/app_localizations.dart';
import '../services/monetization_service.dart';

/// Shows [child] to Pro customers and a gentle invitation to everyone else.
/// Writing is never behind this gate; only the extras are.
class ProGate extends ConsumerWidget {
  const ProGate({super.key, required this.child, this.icon = Icons.insights});

  final Widget child;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(monetizationProvider.select((s) => s.isPro));
    if (isPro) return child;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.t('pro.gate.title'),
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.t('pro.gate.body'),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: () => context.push('/paywall'),
                icon: const Icon(Icons.workspace_premium_outlined),
                label: Text(l10n.t('pro.gate.action')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
