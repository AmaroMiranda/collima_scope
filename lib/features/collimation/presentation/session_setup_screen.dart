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
class SessionSetupScreen extends ConsumerStatefulWidget {
  const SessionSetupScreen({super.key});

  @override
  ConsumerState<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends ConsumerState<SessionSetupScreen> {
  String? _telescopeId;
  String? _adapterId;
  bool _advancedMode = false;

  @override
  Widget build(BuildContext context) {
    final telescopes = ref.watch(telescopesProvider);
    final adapters = ref.watch(adaptersProvider);
    final scheme = Theme.of(context).colorScheme;

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

          final adapterList = adapters.valueOrNull ?? const <AdapterProfile>[];
          final selectedTelescope = scopes
                  .where((t) => t.id == _telescopeId)
                  .firstOrNull ??
              scopes.first;
          final selectedAdapter =
              adapterList.where((a) => a.id == _adapterId).firstOrNull;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Telescópio',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...scopes.map((t) => Card(
                    child: RadioListTile<String>(
                      value: t.id,
                      groupValue: selectedTelescope.id,
                      onChanged: (v) => setState(() => _telescopeId = v),
                      title: Text(t.name),
                      subtitle: Text(
                          '${t.type.label} · Focador ${t.focuserSize.label}'
                          '${t.apertureMm != null ? ' · ${t.apertureMm!.toStringAsFixed(0)} mm' : ''}'),
                    ),
                  )),
              const SizedBox(height: 20),
              Text('Adaptador (opcional)',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: RadioListTile<String?>(
                  value: null,
                  groupValue: selectedAdapter?.id,
                  onChanged: (_) => setState(() => _adapterId = null),
                  title: const Text('Sem adaptador'),
                  subtitle: const Text('Modo referência visual'),
                ),
              ),
              ...adapterList.map((a) => Card(
                    child: RadioListTile<String?>(
                      value: a.id,
                      groupValue: selectedAdapter?.id,
                      onChanged: (v) => setState(() => _adapterId = v),
                      title: Text(a.name),
                      subtitle: Text(a.isValidated
                          ? 'Validado · ${a.phoneMountType.label}'
                          : 'Não validado · ${a.phoneMountType.label}'),
                      secondary: a.isValidated
                          ? Icon(Icons.verified, color: scheme.secondary)
                          : null,
                    ),
                  )),
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
                              ? 'Modo referência visual. Para maior precisão, '
                                  'use um adaptador centralizado no focador.'
                              : selectedAdapter.isValidated
                                  ? 'Modo assistido com adaptador calibrado.'
                                  : 'Modo manual assistido. Valide o adaptador '
                                      'na etapa de calibração para maior precisão.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: SwitchListTile(
                  title: const Text('Modo avançado'),
                  subtitle: const Text(
                      'Pular calibração e ir direto para a colimação'),
                  value: _advancedMode,
                  onChanged: (v) => setState(() => _advancedMode = v),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  final previewCalibrated =
                      ref.read(previewCalibratedProvider);
                  ref.read(collimationControllerProvider.notifier).startSession(
                        telescope: selectedTelescope,
                        adapter: selectedAdapter,
                        previewAlreadyCalibrated: previewCalibrated,
                        advancedMode: _advancedMode,
                      );
                  context.pushReplacement('/collimate');
                },
                icon: const Icon(Icons.videocam),
                label: const Text('Abrir câmera'),
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}
