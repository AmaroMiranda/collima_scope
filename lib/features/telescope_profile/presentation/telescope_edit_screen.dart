import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/local_store.dart';
import '../application/telescope_providers.dart';
import '../domain/telescope_profile.dart';

class TelescopeEditScreen extends ConsumerStatefulWidget {
  final String? profileId;

  const TelescopeEditScreen({super.key, this.profileId});

  @override
  ConsumerState<TelescopeEditScreen> createState() =>
      _TelescopeEditScreenState();
}

class _TelescopeEditScreenState extends ConsumerState<TelescopeEditScreen> {
  final _nameCtrl = TextEditingController();
  final _apertureCtrl = TextEditingController();
  final _focalCtrl = TextEditingController();
  TelescopeType _type = TelescopeType.newtonian;
  FocuserSize _focuserSize = FocuserSize.onePointTwentyFive;
  bool _hasCenterMark = true;
  int _screwCount = 3;
  bool _secondaryOffsetAware = true;
  bool _loaded = false;
  TelescopeProfile? _existing;

  @override
  void initState() {
    super.initState();
    // O estado do botão Salvar depende do nome — rebuild a cada tecla.
    _nameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _apertureCtrl.dispose();
    _focalCtrl.dispose();
    super.dispose();
  }

  void _loadIfNeeded(List<TelescopeProfile> all) {
    if (_loaded || widget.profileId == null) return;
    final found = all.where((t) => t.id == widget.profileId).firstOrNull;
    if (found != null) {
      _existing = found;
      _nameCtrl.text = found.name;
      _apertureCtrl.text = found.apertureMm?.toStringAsFixed(0) ?? '';
      _focalCtrl.text = found.focalLengthMm?.toStringAsFixed(0) ?? '';
      _type = found.type;
      _focuserSize = found.focuserSize;
      _hasCenterMark = found.hasPrimaryCenterMark;
      _screwCount = found.primaryScrewCount;
      _secondaryOffsetAware = found.secondaryOffsetAware;
    }
    _loaded = true;
  }

  @override
  Widget build(BuildContext context) {
    final telescopes = ref.watch(telescopesProvider);

    return Scaffold(
      appBar: AppBar(
          title: Text(widget.profileId == null
              ? 'Novo telescópio'
              : 'Editar telescópio')),
      body: SafeArea(
          child: telescopes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (list) {
          _loadIfNeeded(list);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _nameCtrl,
                decoration:
                    const InputDecoration(labelText: 'Nome do telescópio'),
              ),
              const SizedBox(height: 16),
              Text('Tipo', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 6),
              SegmentedButton<TelescopeType>(
                segments: TelescopeType.values
                    .map((t) => ButtonSegment(value: t, label: Text(t.label)))
                    .toList(),
                selected: {_type},
                onSelectionChanged: (v) => setState(() => _type = v.first),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _apertureCtrl,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Abertura (mm)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _focalCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Distância focal (mm)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Tamanho do focalizador',
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
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Primário tem marca central'),
                value: _hasCenterMark,
                onChanged: (v) => setState(() => _hasCenterMark = v),
              ),
              Text('Parafusos do primário',
                  style: Theme.of(context).textTheme.labelMedium),
              Slider(
                value: _screwCount.toDouble(),
                min: 3,
                max: 6,
                divisions: 3,
                label: '$_screwCount',
                onChanged: (v) => setState(() => _screwCount = v.round()),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Secundário pode ter offset'),
                subtitle: const Text(
                    'Recomendado para Newtonianos de relação focal curta'),
                value: _secondaryOffsetAware,
                onChanged: (v) => setState(() => _secondaryOffsetAware = v),
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
                        .read(telescopesProvider.notifier)
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
    final now = DateTime.now();
    final profile = TelescopeProfile(
      id: _existing?.id ?? newId(),
      name: name,
      type: _type,
      apertureMm: double.tryParse(_apertureCtrl.text),
      focalLengthMm: double.tryParse(_focalCtrl.text),
      focuserSize: _focuserSize,
      hasPrimaryCenterMark: _hasCenterMark,
      primaryScrewCount: _screwCount,
      secondaryOffsetAware: _secondaryOffsetAware,
      createdAt: _existing?.createdAt ?? now,
      updatedAt: now,
    );
    await ref.read(telescopesProvider.notifier).save(profile);
    if (context.mounted) context.pop();
  }
}
