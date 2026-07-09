import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/collimation_controller.dart';
import '../domain/guide_style.dart';
import '../domain/guides.dart';

/// Painel de edição de guias embutido na tela da câmera.
///
/// Diferente de um modal, ocupa só a parte de baixo e deixa o preview
/// visível — os ajustes aplicam ao vivo. As chips no topo permitem
/// selecionar QUALQUER guia da etapa, não só a recém-criada.
class GuideEditorPanel extends ConsumerWidget {
  final VoidCallback onClose;

  const GuideEditorPanel({super.key, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(collimationControllerProvider);
    final controller = ref.read(collimationControllerProvider.notifier);
    final guide = state.selectedGuide ??
        (state.guides.isNotEmpty ? state.guides.first : null);

    if (guide != null && state.selectedGuideId == null) {
      // Garante uma seleção inicial válida sem esperar o usuário tocar.
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => controller.selectGuide(guide.id));
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xEE0D1017),
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: state.guides.map((g) {
                          final selected = g.id == guide?.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(g.name,
                                  style: const TextStyle(fontSize: 12)),
                              avatar: g.visible
                                  ? null
                                  : const Icon(Icons.visibility_off, size: 14),
                              selected: selected,
                              onSelected: (_) => controller.selectGuide(g.id),
                              visualDensity: VisualDensity.compact,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Fechar editor',
                    onPressed: onClose,
                  ),
                ],
              ),
              if (guide != null) _GuideControls(guide: guide),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideControls extends ConsumerWidget {
  final CollimationGuide guide;

  const _GuideControls({required this.guide});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(collimationControllerProvider.notifier);

    final radius = switch (guide) {
      CircleGuide g => g.radius,
      ScrewMarkerGuide g => g.radius,
      SpiderGuide g => g.radius,
      CrosshairGuide g => g.armLength,
      _ => null,
    };

    void setRadius(double v) {
      switch (guide) {
        case CircleGuide g:
          controller.updateGuide(g.copyWith(radius: v));
        case ScrewMarkerGuide g:
          controller.updateGuide(g.copyWith(radius: v));
        case SpiderGuide g:
          controller.updateGuide(g.copyWith(radius: v));
        case CrosshairGuide g:
          controller.updateGuide(g.copyWith(armLength: v));
        default:
          break;
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (radius != null)
          _SliderRow(
            label: 'Raio',
            value: radius.clamp(0.02, 0.5),
            min: 0.02,
            max: 0.5,
            onChanged: setRadius,
          ),
        _SliderRow(
          label: 'Espessura',
          value: guide.style.strokeWidth.clamp(0.5, 6.0),
          min: 0.5,
          max: 6.0,
          onChanged: (v) => controller.updateGuide(guide.copyWithCommon(
              style: guide.style.copyWith(strokeWidth: v))),
        ),
        _SliderRow(
          label: 'Opacidade',
          value: guide.style.opacity.clamp(0.1, 1.0),
          min: 0.1,
          max: 1.0,
          onChanged: (v) => controller.updateGuide(
              guide.copyWithCommon(style: guide.style.copyWith(opacity: v))),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            ...GuidePresets.all.entries.map((e) {
              final selected =
                  e.value.colorValue == guide.style.colorValue &&
                      e.value.lineStyle == guide.style.lineStyle;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => controller.updateGuide(guide.copyWithCommon(
                      style: guide.style.copyWith(
                          colorValue: e.value.colorValue,
                          lineStyle: e.value.lineStyle))),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(e.value.colorValue),
                      border: Border.all(
                        color: selected ? Colors.white : Colors.white24,
                        width: selected ? 2.5 : 1,
                      ),
                    ),
                    child: e.value.lineStyle == LineStyle.dashed
                        ? const Icon(Icons.more_horiz,
                            size: 16, color: Colors.black87)
                        : null,
                  ),
                ),
              );
            }),
            const Spacer(),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(guide.locked ? Icons.lock : Icons.lock_open,
                  size: 20),
              tooltip: guide.locked ? 'Desbloquear' : 'Bloquear',
              onPressed: () => controller
                  .updateGuide(guide.copyWithCommon(locked: !guide.locked)),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(
                  guide.visible ? Icons.visibility : Icons.visibility_off,
                  size: 20),
              tooltip: guide.visible ? 'Ocultar' : 'Mostrar',
              onPressed: () => controller
                  .updateGuide(guide.copyWithCommon(visible: !guide.visible)),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.center_focus_weak, size: 20),
              tooltip: 'Centralizar',
              onPressed: () => controller.resetGuideToCenter(guide.id),
            ),
            if (guide is CircleGuide) ...[
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.copy, size: 20),
                tooltip: 'Duplicar',
                onPressed: () => controller.duplicateGuide(guide.id),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: 'Remover',
                onPressed: () => controller.removeGuide(guide.id),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
