import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/r_personal_service.dart';

class EchoesScreen extends StatefulWidget {
  const EchoesScreen({super.key});
  @override
  State<EchoesScreen> createState() => _EchoesScreenState();
}

class _EchoesScreenState extends State<EchoesScreen> {
  final _service = RPersonalService();
  List<EchoRecord>? _echoes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final echoes = await _service.loadEchoes();
    if (mounted) setState(() => _echoes = echoes);
  }

  @override
  Widget build(BuildContext context) {
    final echoes = _echoes;
    return Scaffold(
      appBar: AppBar(title: const Text('Echoes')),
      body:
          echoes == null
              ? const Center(child: CircularProgressIndicator())
              : echoes.isEmpty
              ? const _EmptyEchoes()
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: echoes.length,
                itemBuilder: (_, index) => _EchoCard(record: echoes[index]),
              ),
    );
  }
}

class _EchoCard extends StatelessWidget {
  const _EchoCard({required this.record});
  final EchoRecord record;

  @override
  Widget build(BuildContext context) {
    final mood = record.original.mood;
    final resolved = record.resolution != null;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  resolved
                      ? Icons.wb_sunny_outlined
                      : Icons.nightlight_outlined,
                  color: resolved ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    resolved
                        ? 'Resolved echo'
                        : 'An echo waiting for a response',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  mood,
                  style: const TextStyle(color: AppColors.textTertiary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              record.original.content,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Text(
              'Original: ${_date(record.original.createdAt)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            if (record.resolution case final resolution?) ...[
              const Divider(height: 24),
              const Text(
                'Later positive entry',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                resolution.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                'Resolved: ${_date(resolution.createdAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _date(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}

class _EmptyEchoes extends StatelessWidget {
  const _EmptyEchoes();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Text(
        'Echoes appear when Journal entries with a difficult mood have a later positive entry 3–90 days afterward.',
        textAlign: TextAlign.center,
      ),
    ),
  );
}
