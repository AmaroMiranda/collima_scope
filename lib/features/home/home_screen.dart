import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../adapter_profile/application/adapter_providers.dart';
import '../collimation/domain/collimation_workflow.dart';
import '../history/application/session_providers.dart';
import '../history/domain/collimation_session.dart';
import '../telescope_profile/application/telescope_providers.dart';
import '../telescope_profile/domain/telescope_profile.dart';

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
    final telescopes = ref.watch(telescopesProvider).valueOrNull ?? const [];
    final adapters = ref.watch(adaptersProvider).valueOrNull ?? const [];
    final sessions = ref.watch(sessionsProvider).valueOrNull ?? const [];

    // Equipamento em destaque: telescópio mais recente e o melhor adaptador
    // disponível (alinhado manualmente > sem alinhamento).
    final telescope = telescopes.isEmpty
        ? null
        : (List.of(telescopes)
              ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)))
            .first;
    final adapter = adapters.where((a) => a.isValidated).firstOrNull ??
        adapters.firstOrNull;
    final lastSession = sessions.firstOrNull;

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
            'Alinhamento assistido para telescópios Newtonianos',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          // Painel de prontidão (§6): a primeira tela informa qual equipamento
          // está pronto e qual precisão está disponível — não é só um menu.
          _ReadinessPanel(
            telescope: telescope,
            adapterName: adapter?.name,
            adapterAligned: adapter?.isValidated ?? false,
            hasAdapter: adapter != null,
            onPrimaryAction: () => context.push(
                telescope == null ? '/telescopes/edit' : '/setup'),
            primaryLabel: telescope == null
                ? 'Configurar equipamento'
                : 'Iniciar nova colimação',
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
                  title: 'Sessões',
                  onTap: () => context.push('/history'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SmallActionCard(
                  icon: Icons.menu_book_outlined,
                  title: 'Aprender',
                  onTap: () => context.push('/guide'),
                ),
              ),
            ],
          ),
          if (lastSession != null) ...[
            const SizedBox(height: 20),
            Text('SESSÃO RECENTE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.4,
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                    )),
            const SizedBox(height: 8),
            _RecentSessionCard(
              session: lastSession,
              telescopeName: telescopes
                      .where((t) => t.id == lastSession.telescopeProfileId)
                      .firstOrNull
                      ?.name ??
                  'Telescópio removido',
              onTap: () => context.push('/history'),
            ),
          ],
          const SizedBox(height: 20),
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

/// Painel de prontidão (§6): telescópio, adaptador, estado do alinhamento e
/// precisão disponível, com a ação principal adequada ao estado.
class _ReadinessPanel extends StatelessWidget {
  final TelescopeProfile? telescope;
  final String? adapterName;
  final bool hasAdapter;
  final bool adapterAligned;
  final String primaryLabel;
  final VoidCallback onPrimaryAction;

  const _ReadinessPanel({
    required this.telescope,
    required this.adapterName,
    required this.hasAdapter,
    required this.adapterAligned,
    required this.primaryLabel,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final precision = !hasAdapter
        ? 'Referência visual'
        : adapterAligned
            ? 'Alinhamento manual'
            : 'Referência visual';

    Widget statusRow(String label, String value, {Color? valueColor}) =>
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
              Flexible(
                child: Text(value,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: valueColor ?? scheme.onSurface,
                    )),
              ),
            ],
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PRONTIDÃO',
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.4,
                  color: scheme.primary,
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 10),
            if (telescope == null) ...[
              Text('Nenhum telescópio cadastrado',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Cadastre o equipamento para o app adaptar guias, avisos e '
                'exigência de colimação.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ] else ...[
              Text(telescope!.name, style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(telescope!.techSummary,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 6),
              const Divider(),
              statusRow('Adaptador', adapterName ?? 'Nenhum'),
              statusRow(
                'Alinhamento',
                !hasAdapter
                    ? '—'
                    : adapterAligned
                        ? 'Manual'
                        : 'Não registrado',
                valueColor: hasAdapter && adapterAligned
                    ? scheme.tertiary
                    : null,
              ),
              statusRow('Precisão disponível', precision),
              statusRow('Exigência', telescope!.collimationDemandLabel,
                  valueColor:
                      telescope!.isFastScope ? scheme.tertiary : null),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onPrimaryAction,
                child: Text(primaryLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentSessionCard extends StatelessWidget {
  final CollimationSession session;
  final String telescopeName;
  final VoidCallback onTap;

  const _RecentSessionCard({
    required this.session,
    required this.telescopeName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final finished = session.finishedAt != null;
    final when = DateFormat('dd/MM/yyyy · HH:mm').format(session.startedAt);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(telescopeName,
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: (finished ? scheme.secondary : scheme.primary)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color:
                              (finished ? scheme.secondary : scheme.primary)
                                  .withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      finished ? 'Concluída' : 'Rascunho',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: finished ? scheme.secondary : scheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('$when · ${session.mode.label}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
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
