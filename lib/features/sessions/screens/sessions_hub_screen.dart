import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/sessions_data.dart';
import '../models/session.dart';
import '../widgets/session_card.dart';

class SessionsHubScreen extends StatelessWidget {
  const SessionsHubScreen({super.key});

  void _openSession(BuildContext context, Session session) {
    context.push('/sessions/run?id=${session.id}');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<Session> sessions = SessionsData.all;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'السلاسل',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'كيف تشعر الآن؟',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'اختر ما تشعر به، وسنبدأ معًا',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              physics: const BouncingScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.05,
              ),
              itemCount: sessions.length,
              itemBuilder: (BuildContext context, int index) {
                final Session session = sessions[index];

                return SessionCard(
                  session: session,
                  onTap: () => _openSession(context, session),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
