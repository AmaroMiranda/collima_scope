import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../adapter_profile/application/adapter_providers.dart';
import '../../adapter_profile/domain/adapter_profile.dart';
import '../../telescope_profile/application/telescope_providers.dart';
import '../../telescope_profile/domain/telescope_profile.dart';
import '../application/collimation_controller.dart';

/// Escolha de telescópio e adaptador antes de abrir a câmera.
///
/// Quando só existe um telescópio (e no máximo um adaptador) não há de fato
/// nenhuma escolha a fazer — a tela mostra um resumo compacto em vez de
/// listas de seleção, e pré-marca o equipamento usado na última sessão
/// (simplificação pedida por usuários novos E experientes: menos decisões
/// visíveis, menos toques para quem já configurou tudo antes).
class SessionSetupScreen extends ConsumerStatefulWidget {
  const SessionSetupScreen({super.key});

  @override
  ConsumerState<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends ConsumerState<SessionSetupScreen> {
  String? _telescopeId;
  String? _adapterId;
  bool _preferAdvanced = false;
  bool _prefsLoaded = false;
  final _advancedController = ExpansibleController();

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = ref.read(appPrefsProvider);
    final lastTelescope = await prefs.getLastTelescopeId();
    final lastAdapter = await prefs.getLastAdapterId();
    final preferAdvanced = await prefs.getPreferAdvancedMode();
    if (!mounted) return;
    setState(() {
      _telescopeId = lastTelescope;
      _adapterId = lastAdapter;
      _preferAdvanced = preferAdvanced;
      _prefsLoaded = true;
    });
    // Reabre "Opções avançadas" já expandida se essa foi a última escolha —
    // continua exigindo o toque em "Iniciar sem verificações" para valer.
    if (preferAdvanced) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _advancedController.expand());
    }
  }

  @override
  void dispose() {
    _advancedController.dispose();
    super.dispose();
  }

  void _start(TelescopeProfile telescope, AdapterProfile? adapter,
      {required bool advanced}) {
    ref.read(collimationControllerProvider.notifier).startSession(
          telescope: telescope,
          adapter: adapter,
          advancedMode: advanced,
        );
    context.pushReplacement('/collimate');
  }

  @override
  Widget build(BuildContext context) {
    final telescopes = ref.watch(telescopesProvider);
    final adapters = ref.watch(adaptersProvider);
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Nova sessão')),
      body: SafeArea(
          child: telescopes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (scopes) {
          if (scopes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle_outlined, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Cadastre seu telescópio antes de iniciar a colimação.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => context.push('/telescopes/edit'),
                      icon: const Icon(Icons.add),
                      label: const Text('Cadastrar telescópio'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!_prefsLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final adapterList = adapters.valueOrNull ?? const <AdapterProfile>[];
          final selectedTelescope =
              scopes.where((t) => t.id == _telescopeId).firstOrNull ??
                  scopes.first;
          final selectedAdapter =
              adapterList.where((a) => a.id == _adapterId).firstOrNull;
          final singleTelescope = scopes.length == 1;
          final singleAdapter = adapterList.length == 1;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Telescópio', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (singleTelescope)
                _EquipmentSummaryCard(
                  icon: Icons.circle_outlined,
                  title: selectedTelescope.name,
                  subtitle:
                      '${selectedTelescope.type.label} · ${selectedTelescope.techSummary}\n'
                      '${selectedTelescope.collimationDemandLabel}',
                )
              else
                ...scopes.map((t) => Card(
                      child: RadioListTile<String>(
                        value: t.id,
                        groupValue: selectedTelescope.id,
                        onChanged: (v) => setState(() => _telescopeId = v),
                        title: Text(t.name),
                        subtitle: Text(
                            '${t.type.label} · ${t.techSummary}\n${t.collimationDemandLabel}'),
                        isThreeLine: true,
                      ),
                    )),
              if (selectedTelescope.isFastScope)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.speed, color: scheme.tertiary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Telescópio rápido: a tolerância de colimação é '
                              'pequena${selectedTelescope.primaryAxialToleranceMm != null ? ' (~${selectedTelescope.primaryAxialToleranceMm!.toStringAsFixed(2)} mm no eixo do primário)' : ''}. '
                              'Considere validar com Cheshire e star test.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Text('Adaptador (opcional)',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (adapterList.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: scheme.tertiary, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                              'Nenhum adaptador cadastrado — modo de '
                              'referência visual.'),
                        ),
                        TextButton(
                          onPressed: () => context.push('/adapters/edit'),
                          child: const Text('Cadastrar'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (singleAdapter)
                _AdapterToggleCard(
                  adapter: adapterList.single,
                  selected: selectedAdapter != null,
                  onChanged: (v) =>
                      setState(() => _adapterId = v ? adapterList.single.id : null),
                )
              else ...[
                Card(
                  child: RadioListTile<String?>(
                    value: null,
                    groupValue: selectedAdapter?.id,
                    onChanged: (_) => setState(() => _adapterId = null),
                    title: const Text('Sem adaptador'),
                    subtitle: const Text('Modo de referência visual'),
                  ),
                ),
                ...adapterList.map((a) => Card(
                      child: RadioListTile<String?>(
                        value: a.id,
                        groupValue: selectedAdapter?.id,
                        onChanged: (v) => setState(() => _adapterId = v),
                        title: Text(a.name),
                        subtitle: Text(a.isValidated
                            ? 'Alinhado manualmente · ${a.phoneMountType.label}'
                            : 'Não alinhado · ${a.phoneMountType.label}'),
                        // Amarelo = alinhamento manual; verde fica reservado
                        // para calibração medida (ainda inexistente).
                        secondary: a.isValidated
                            ? Icon(Icons.tune, color: scheme.tertiary)
                            : null,
                      ),
                    )),
              ],
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(
                        selectedAdapter == null
                            ? Icons.info_outline
                            : Icons.check_circle_outline,
                        color: selectedAdapter == null
                            ? scheme.tertiary
                            : scheme.secondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectedAdapter == null
                              ? 'Modo de referência visual. Para maior '
                                  'precisão, use um adaptador centralizado '
                                  'no focalizador.'
                              : selectedAdapter.isValidated
                                  ? 'Modo assistido com alinhamento manual do '
                                      'adaptador. O aplicativo ainda não mede '
                                      'o erro residual do alinhamento.'
                                  : 'Modo assistido sem alinhamento '
                                      'registrado. Alinhe o adaptador na '
                                      'etapa correspondente.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _start(selectedTelescope, selectedAdapter,
                    advanced: false),
                icon: const Icon(Icons.videocam),
                label: const Text('Abrir câmera'),
              ),
              const SizedBox(height: 8),
              // Ação perigosa fora do caminho comum (UX P0.7): recolhida,
              // com consequências explícitas. Reabre expandida sozinha se
              // foi a última escolha (ver _loadPrefs) — continua exigindo
              // toque explícito em "Iniciar sem verificações" para valer.
              ExpansionTile(
                controller: _advancedController,
                initiallyExpanded: _preferAdvanced,
                tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                title: Text('Opções avançadas', style: theme.textTheme.titleSmall),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pular verificações pode reduzir a precisão e fazer '
                          'o aplicativo usar referências incompatíveis com a '
                          'montagem atual.',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.tertiary),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => _start(
                                selectedTelescope, selectedAdapter,
                                advanced: true),
                            child: const Text('Iniciar sem verificações'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}

/// Resumo compacto quando não há escolha real a fazer (um único telescópio
/// cadastrado) — evita mostrar uma lista de seleção com um item só.
class _EquipmentSummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EquipmentSummaryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quando só existe um adaptador cadastrado, um switch substitui o par de
/// cards de rádio ("Sem adaptador" / o adaptador) — a mesma escolha, com
/// metade do espaço visual.
class _AdapterToggleCard extends StatelessWidget {
  final AdapterProfile adapter;
  final bool selected;
  final ValueChanged<bool> onChanged;

  const _AdapterToggleCard({
    required this.adapter,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: SwitchListTile(
        value: selected,
        onChanged: onChanged,
        title: Text('Usar ${adapter.name}'),
        subtitle: Text(selected
            ? (adapter.isValidated
                ? 'Alinhado manualmente · ${adapter.phoneMountType.label}'
                : 'Não alinhado · ${adapter.phoneMountType.label}')
            : 'Desligado: modo de referência visual'),
        secondary: Icon(
          Icons.smartphone,
          color: selected && adapter.isValidated ? scheme.tertiary : null,
        ),
      ),
    );
  }
}
