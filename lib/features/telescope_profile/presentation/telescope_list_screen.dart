import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/telescope_providers.dart';
import '../domain/telescope_profile.dart'
    show TelescopeTypeLabel;

class TelescopeListScreen extends ConsumerWidget {
  const TelescopeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telescopes = ref.watch(telescopesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Telescópios')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/telescopes/edit'),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
          child: telescopes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nenhum telescópio cadastrado. Toque em + para adicionar.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final t = list[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.circle_outlined),
                  title: Text(t.name),
                  subtitle: Text(
                      '${t.type.label} · ${t.techSummary}\n'
                      '${t.collimationDemandLabel} · ${t.primaryScrewCount} parafusos'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/telescopes/edit?id=${t.id}'),
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
