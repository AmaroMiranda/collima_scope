import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../telescope_profile/domain/telescope_profile.dart'
    show FocuserSizeLabel;
import '../application/adapter_providers.dart';
import '../domain/adapter_profile.dart' show PhoneMountTypeLabel;

class AdapterListScreen extends ConsumerWidget {
  const AdapterListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adapters = ref.watch(adaptersProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Adaptadores')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/adapters/edit'),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
          child: adapters.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nenhum adaptador cadastrado. Sem adaptador, o app usa o '
                  'modo referência visual.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final a = list[i];
              return Card(
                child: ListTile(
                  leading: Icon(
                    a.isValidated ? Icons.verified : Icons.smartphone,
                    color: a.isValidated ? scheme.secondary : null,
                  ),
                  title: Text(a.name),
                  subtitle: Text(
                      '${a.phoneMountType.label} · Focador ${a.focuserSize.label}'
                      '${a.isValidated ? ' · Validado' : ' · Não validado'}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/adapters/edit?id=${a.id}'),
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
