import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../collimation/domain/collimation_workflow.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _safetyDialogShown = false;

  @override
  Widget build(BuildContext context) {
    // Etapa 0 — aviso de segurança solar no primeiro uso.
    final safetyAccepted = ref.watch(safetyAcceptedProvider);
    if (safetyAccepted == false && !_safetyDialogShown) {
      _safetyDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showSafetyDialog());
    }

    final redMode = ref.watch(redModeProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CollimaScope',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Modo vermelho',
            icon: Icon(redMode ? Icons.nightlight : Icons.nightlight_outlined),
            onPressed: () => ref.read(redModeProvider.notifier).toggle(),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Assistente visual de colimação por câmera do celular',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 20),
          _BigActionCard(
            icon: Icons.center_focus_strong,
            title: 'Iniciar colimação',
            subtitle: 'Newtoniano / Dobsoniano, guiado passo a passo',
            onTap: () => context.push('/setup'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SmallActionCard(
                  icon: Icons.circle_outlined,
                  title: 'Telescópios',
                  onTap: () => context.push('/telescopes'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SmallActionCard(
                  icon: Icons.smartphone,
                  title: 'Adaptadores',
                  onTap: () => context.push('/adapters'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SmallActionCard(
                  icon: Icons.history,
                  title: 'Histórico',
                  onTap: () => context.push('/history'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SmallActionCard(
                  icon: Icons.menu_book_outlined,
                  title: 'Guia',
                  onTap: () => context.push('/guide'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: scheme.tertiary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      kSafetyWarning,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Future<void> _showSafetyDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.wb_sunny_outlined, size: 40),
        title: const Text('Segurança primeiro'),
        content: const Text(kSafetyWarning),
        actions: [
          FilledButton(
            onPressed: () {
              ref.read(safetyAcceptedProvider.notifier).accept();
              Navigator.of(context).pop();
            },
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }
}

class _BigActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _BigActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 32, color: scheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SmallActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            children: [
              Icon(icon, size: 28, color: scheme.primary),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}
