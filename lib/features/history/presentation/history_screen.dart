import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../application/session_providers.dart';
import '../domain/collimation_session.dart' show CollimationModeLabel;

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de sessões')),
      body: SafeArea(
          child: sessions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Nenhuma sessão salva ainda.',
                    textAlign: TextAlign.center),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final s = list[i];
              return Card(
                child: ListTile(
                  leading: Icon(s.finishedAt != null
                      ? Icons.check_circle_outline
                      : Icons.pending_outlined),
                  title: Text(dateFmt.format(s.startedAt)),
                  subtitle: Text(s.mode.label),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/history/session?id=${s.id}'),
                ),
              );
            },
          );
        },
      ),
      ),
    );
  }
}
