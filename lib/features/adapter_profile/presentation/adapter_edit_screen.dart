import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/local_store.dart';
import '../../telescope_profile/domain/telescope_profile.dart'
    show FocuserSize, FocuserSizeLabel;
import '../application/adapter_providers.dart';
import '../domain/adapter_profile.dart';

class AdapterEditScreen extends ConsumerStatefulWidget {
  final String? profileId;

  const AdapterEditScreen({super.key, this.profileId});

  @override
  ConsumerState<AdapterEditScreen> createState() => _AdapterEditScreenState();
}

class _AdapterEditScreenState extends ConsumerState<AdapterEditScreen> {
  final _nameCtrl = TextEditingController();
  FocuserSize _focuserSize = FocuserSize.onePointTwentyFive;
  PhoneMountType _mountType = PhoneMountType.generic;
  bool _validated = false;
  bool _loaded = false;
  AdapterProfile? _existing;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _loadIfNeeded(List<AdapterProfile> all) {
    if (_loaded || widget.profileId == null) return;
    final found = all.where((a) => a.id == widget.profileId).firstOrNull;
    if (found != null) {
      _existing = found;
      _nameCtrl.text = found.name;
      _focuserSize = found.focuserSize;
      _mountType = found.phoneMountType;
      _validated = found.isValidated;
    }
    _loaded = true;
  }

  @override
  Widget build(BuildContext context) {
    final adapters = ref.watch(adaptersProvider);

    return Scaffold(
      appBar: AppBar(
          title: Text(
              widget.profileId == null ? 'Novo adaptador' : 'Editar adaptador')),
      body: SafeArea(
          child: adapters.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (list) {
          _loadIfNeeded(list);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nome do adaptador'),
              ),
              const SizedBox(height: 16),
              Text('Tamanho do focador',
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 6),
              SegmentedButton<FocuserSize>(
                segments: FocuserSize.values
                    .map((f) => ButtonSegment(value: f, label: Text(f.label)))
                    .toList(),
                selected: {_focuserSize},
                onSelectionChanged: (v) =>
                    setState(() => _focuserSize = v.first),
              ),
              const SizedBox(height: 16),
              Text('Tipo de encaixe',
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: PhoneMountType.values
                    .map((m) => ChoiceChip(
                          label: Text(m.label),
                          selected: _mountType == m,
                          onSelected: (_) => setState(() => _mountType = m),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Adaptador validado'),
                subtitle: const Text(
                    'Marque após confirmar que a câmera está centralizada '
                    'e estável no focador (etapa de calibração)'),
                value: _validated,
                onChanged: (v) => setState(() => _validated = v),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _nameCtrl.text.trim().isEmpty
                    ? null
                    : () => _save(context),
                child: const Text('Salvar'),
              ),
              if (_existing != null) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref
                        .read(adaptersProvider.notifier)
                        .remove(_existing!.id);
                    if (context.mounted) context.pop();
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Excluir'),
                ),
              ],
            ],
          );
        },
      ),
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final profile = AdapterProfile(
      id: _existing?.id ?? newId(),
      name: name,
      focuserSize: _focuserSize,
      phoneMountType: _mountType,
      cameraOffsetX: _existing?.cameraOffsetX ?? 0,
      cameraOffsetY: _existing?.cameraOffsetY ?? 0,
      validatedAt: _validated ? (_existing?.validatedAt ?? DateTime.now()) : null,
    );
    await ref.read(adaptersProvider.notifier).save(profile);
    if (context.mounted) context.pop();
  }
}
