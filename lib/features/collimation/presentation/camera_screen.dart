import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/camera/camera_engine.dart';
import '../../../core/export/overlay_exporter.dart';
import '../../../core/storage/local_store.dart';
import '../../../core/viewport/viewport_transform.dart';
import '../application/collimation_controller.dart';
import '../domain/collimation_workflow.dart';
import '../domain/guides.dart';
import 'collimation_camera_viewport.dart';
import 'guide_editor_panel.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  final _engine = CameraEngine();
  bool _initializing = true;
  String? _error;
  bool _mainCameraConfirmed = true;
  bool _editorOpen = false;
  ViewportTransform? _transform;
  String? _draggingGuideId;

  /// Serializa inicialização/descarte da câmera (auditoria P2.3): sem isto,
  /// um pause/resume rápido dispara init e dispose concorrentes e a câmera
  /// volta preta.
  Future<void> _lifecycleChain = Future.value();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  void _init() {
    _lifecycleChain = _lifecycleChain.then((_) async {
      try {
        final selection = await _engine.initialize();
        if (!mounted) return;
        setState(() {
          _mainCameraConfirmed = selection.mainCameraConfirmed;
          _initializing = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _error = '$e';
          _initializing = false;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lifecycleChain = _lifecycleChain.then((_) => _engine.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _lifecycleChain = _lifecycleChain.then((_) => _engine.dispose());
    } else if (state == AppLifecycleState.resumed) {
      _lifecycleChain = _lifecycleChain.then((_) async {
        if (!mounted || _engine.isReady) return;
        _init();
      });
    }
  }

  /// Confirmação antes de abandonar uma sessão com ajustes (UX P0.5).
  Future<void> _confirmExit(CollimationState state,
      CollimationController controller) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da sessão?'),
        content: const Text('Os ajustes não salvos serão perdidos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('stay'),
            child: const Text('Continuar sessão'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('draft'),
            child: const Text('Salvar rascunho e sair'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('discard'),
            child: const Text('Sair sem salvar'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 'draft':
        await controller.saveSession();
        if (mounted) context.go('/');
      case 'discard':
        context.go('/');
      default:
        break; // continuar na sessão
    }
  }

  /// Ação "Há deformação" da etapa de verificação da imagem (auditoria P0.1).
  Future<void> _reportDistortion() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Imagem com deformação'),
        content: const Text(
            'Não continue com esta câmera/lente: as guias circulares não '
            'serão confiáveis.\n\nComo testar: aponte para um objeto '
            'perfeitamente circular (CD, tampa, gabarito impresso), '
            'centralize-o e gire o aparelho — a borda deve continuar '
            'coincidindo com o círculo de referência em qualquer orientação. '
            'Se deformar, tente outra lente (evite a ultrawide), desligue '
            'ajustes automáticos de "correção" da câmera, ou use outro '
            'aparelho.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  Future<void> _finishSession(CollimationController controller) async {
    await controller.saveSession(finished: true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Sessão concluída e salva no histórico.')));
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Câmera')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Não foi possível abrir a câmera:\n$_error',
                textAlign: TextAlign.center),
          ),
        ),
      );
    }
    if (_initializing || !_engine.isReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final collimation = ref.watch(collimationControllerProvider);
    final controller = ref.read(collimationControllerProvider.notifier);
    final stepInfo = collimation.stepInfo;
    final telescope = collimation.telescope;

    // Nota dinâmica conforme o equipamento (auditoria P0.4).
    String? equipmentNote;
    if (stepInfo.step == CollimationStep.adjustPrimary &&
        telescope != null &&
        !telescope.hasPrimaryCenterMark) {
      equipmentNote =
          'Este telescópio foi cadastrado sem marca central no primário: as '
          'referências de reflexo não se aplicam. Use uma referência física '
          '(Cheshire/tampa) e considere marcar o centro do espelho.';
    } else if (telescope != null &&
        telescope.isFastScope &&
        (stepInfo.step == CollimationStep.adjustPrimary ||
            stepInfo.step == CollimationStep.alignSecondaryToPrimary)) {
      final tol = telescope.primaryAxialToleranceMm;
      equipmentNote =
          'Telescópio rápido (${telescope.techSummary.split(' · ').first}): '
          'a tolerância de colimação é pequena'
          '${tol != null ? ' (~${tol.toStringAsFixed(2)} mm no eixo do primário)' : ''}. '
          'Prefira validar com referência física e star test.';
    }

    final isVerifyStep = stepInfo.step == CollimationStep.previewCalibration;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTapUp: (details) => _handleTap(
                    details.localPosition, collimation.guides, controller),
                onPanStart: (details) =>
                    _handlePanStart(details.localPosition, collimation.guides),
                onPanUpdate: (details) =>
                    _handlePanUpdate(details.delta, controller),
                onPanEnd: (_) => _draggingGuideId = null,
                child: CollimationCameraViewport(
                  controller: _engine.controller!,
                  guides: collimation.guides,
                  highlightedGuideId: collimation.selectedGuideId,
                  onTransform: (t) => _transform = t,
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: _TopBar(
                stepLabel:
                    'Etapa ${collimation.stepIndex + 1} de ${CollimationWorkflowEngine.steps.length} · ${stepInfo.shortLabel}',
                onClose: () => _confirmExit(collimation, controller),
                onReset: controller.resetStepGuides,
                onStepTap: () => _openStepPicker(collimation, controller),
              ),
            ),
            // Barra de estado da câmera (UX §8.3): zoom, congelamento, modo e
            // avisos perigosos como chips sempre visíveis.
            Positioned(
              top: 56,
              left: 12,
              right: 12,
              child: _CamStatusChips(
                zoom: _engine.zoom,
                frozen: _engine.isFrozen,
                modeLabel: collimation.adapter == null
                    ? 'Referência visual'
                    : (collimation.adapter!.isValidated
                        ? 'Alinhamento manual'
                        : 'Sem alinhamento'),
                lensWarning: !_mainCameraConfirmed,
                warningColor: scheme.tertiary,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _editorOpen
                  ? GuideEditorPanel(
                      onClose: () => setState(() => _editorOpen = false))
                  : _BottomPanel(
                      // Reseta a dica para "recolhida" a cada nova etapa, em
                      // vez de manter o texto aberto sobre a próxima imagem.
                      key: ValueKey(stepInfo.step),
                      onFreeze: () async {
                        await _engine.setFrozen(!_engine.isFrozen);
                        setState(() {});
                      },
                      onTorch: (on) => _engine.setTorch(on),
                      onCapture: () => _capture(collimation, controller),
                      onEditCircles: () =>
                          setState(() => _editorOpen = true),
                      onAddCircle: () {
                        controller.addCircle();
                        setState(() => _editorOpen = true);
                      },
                      frozen: _engine.isFrozen,
                      zoom: _engine.zoom,
                      minZoom: _engine.minZoom,
                      maxZoom: _engine.maxZoom,
                      onZoom: (v) {
                        _engine.setZoom(v);
                        setState(() {});
                      },
                      stepInfo: stepInfo,
                      extraNote: equipmentNote,
                      isFirstStep: collimation.isFirstStep,
                      isLastStep: collimation.isLastStep,
                      onPrevStep: controller.previousStep,
                      // A verificação da imagem nunca marca nada como
                      // "calibrado" (auditoria P0.1/P1.3) — apenas avança
                      // com rótulo honesto.
                      nextLabel: collimation.isLastStep
                          ? 'Concluir sessão'
                          : isVerifyStep
                              ? 'A imagem parece regular'
                              : 'Confirmar e avançar',
                      onNextStep: collimation.isLastStep
                          ? () => _finishSession(controller)
                          : controller.nextStep,
                      onDistortion: isVerifyStep ? _reportDistortion : null,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openStepPicker(
      CollimationState state, CollimationController controller) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        top: false,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: CollimationWorkflowEngine.steps.map((info) {
            final index = CollimationWorkflowEngine.indexOf(info.step);
            final current = info.step == state.step;
            return ListTile(
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: current
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white12,
                child: Text('${index + 1}',
                    style: TextStyle(
                        fontSize: 13,
                        color: current ? Colors.black : Colors.white)),
              ),
              title: Text(info.title),
              subtitle: Text(info.objective,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              selected: current,
              onTap: () {
                controller.goToStep(info.step);
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _handleTap(Offset localPos, List<CollimationGuide> guides,
      CollimationController controller) {
    final t = _transform;
    if (t == null) return;
    final hit = _hitTest(localPos, guides, t);
    controller.selectGuide(hit?.id);
  }

  void _handlePanStart(Offset localPos, List<CollimationGuide> guides) {
    final t = _transform;
    if (t == null) return;
    final hit = _hitTest(localPos, guides, t);
    _draggingGuideId = hit != null && !hit.locked ? hit.id : null;
  }

  void _handlePanUpdate(Offset delta, CollimationController controller) {
    final id = _draggingGuideId;
    final t = _transform;
    if (id == null || t == null) return;
    // Coordenadas normalizadas: X é fração da LARGURA visível e Y da ALTURA
    // (auditoria P1.1). Dividir ambos pelo menor lado fazia a guia andar em
    // proporção diferente do dedo em telas retangulares.
    final rect = t.visibleWidgetRect;
    if (rect.width == 0 || rect.height == 0) return;
    final dx = delta.dx / rect.width;
    final dy = delta.dy / rect.height;
    controller.moveGuide(id, dx, dy);
  }

  CollimationGuide? _hitTest(
      Offset localPos, List<CollimationGuide> guides, ViewportTransform t) {
    CollimationGuide? found;
    double bestDist = double.infinity;
    for (final g in guides.reversed) {
      if (!g.visible || g.locked) continue;
      Offset? center;
      double? radius;
      switch (g) {
        case CircleGuide c:
          center = t.normalizedToScreen(c.center);
          radius = t.normalizedRadiusToScreen(c.radius);
        case CrosshairGuide c:
          center = t.normalizedToScreen(c.center);
          radius = 24;
        default:
          continue;
      }
      final distToEdge = (localPos - center).distance - radius;
      const tolerance = 32.0;
      if (distToEdge.abs() < tolerance && distToEdge.abs() < bestDist) {
        bestDist = distToEdge.abs();
        found = g;
      }
    }
    return found;
  }

  Future<void> _capture(
      CollimationState state, CollimationController controller) async {
    try {
      final file = await _engine.capture();
      final exporter = OverlayExporter();
      final persisted =
          await exporter.persistCapture(file.path, 'capture-${newId()}');
      final isBefore = state.beforeImagePath == null;
      if (isBefore) {
        controller.setBeforeImage(persisted);
      } else {
        controller.setAfterImage(persisted);
      }
      await controller.saveSession();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            isBefore ? 'Imagem inicial salva.' : 'Imagem final salva.'),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Não foi possível capturar a imagem: $e')));
    }
  }
}

class _TopBar extends StatelessWidget {
  final String stepLabel;
  final VoidCallback onClose;
  final VoidCallback onReset;
  final VoidCallback onStepTap;

  const _TopBar({
    required this.stepLabel,
    required this.onClose,
    required this.onReset,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundIconButton(icon: Icons.close, onTap: onClose),
        const Spacer(),
        Material(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onStepTap,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(stepLabel,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 13)),
                  const SizedBox(width: 4),
                  const Icon(Icons.expand_more,
                      color: Colors.white70, size: 16),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
        _RoundIconButton(icon: Icons.refresh, onTap: onReset),
      ],
    );
  }
}

/// Barra de estado da câmera (UX §8.3): condição atual sempre visível, com
/// estados perigosos destacados.
class _CamStatusChips extends StatelessWidget {
  final double zoom;
  final bool frozen;
  final String modeLabel;
  final bool lensWarning;
  final Color warningColor;

  const _CamStatusChips({
    required this.zoom,
    required this.frozen,
    required this.modeLabel,
    required this.lensWarning,
    required this.warningColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip(String text, {Color? color}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xC704070A),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
                color: (color ?? Colors.white).withValues(alpha: 0.25)),
          ),
          child: Text(
            text,
            style: TextStyle(
                color: color ?? Colors.white70,
                fontSize: 10.5,
                fontWeight: FontWeight.w700),
          ),
        );

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        chip('${zoom.toStringAsFixed(1).replaceAll('.', ',')}×'),
        if (frozen) chip('Congelado', color: const Color(0xFF6DE6A3)),
        chip(modeLabel,
            color: modeLabel == 'Alinhamento manual' ? warningColor : null),
        if (lensWarning) chip('Lente não confirmada', color: warningColor),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  const _RoundIconButton(
      {required this.icon, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? Colors.white24 : Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _BottomPanel extends StatefulWidget {
  final VoidCallback onFreeze;
  final ValueChanged<bool> onTorch;
  final VoidCallback onCapture;
  final VoidCallback onEditCircles;
  final VoidCallback onAddCircle;
  final bool frozen;
  final double zoom;
  final double minZoom;
  final double maxZoom;
  final ValueChanged<double> onZoom;
  final StepInfo stepInfo;
  final String? extraNote;
  final bool isFirstStep;
  final bool isLastStep;
  final VoidCallback onPrevStep;
  final VoidCallback onNextStep;
  final String nextLabel;
  final VoidCallback? onDistortion;

  const _BottomPanel({
    super.key,
    required this.onFreeze,
    required this.onTorch,
    required this.onCapture,
    required this.onEditCircles,
    required this.onAddCircle,
    required this.frozen,
    required this.zoom,
    required this.minZoom,
    required this.maxZoom,
    required this.onZoom,
    required this.stepInfo,
    this.extraNote,
    required this.isFirstStep,
    required this.isLastStep,
    required this.onPrevStep,
    required this.onNextStep,
    required this.nextLabel,
    this.onDistortion,
  });

  @override
  State<_BottomPanel> createState() => _BottomPanelState();
}

class _BottomPanelState extends State<_BottomPanel> {
  // Recolhida por padrão (feedback de teste de campo: o texto fixo sobre a
  // câmera atrapalhava a visão durante o ajuste). O widget é recriado com uma
  // key por etapa (ver camera_screen), então este estado volta a "fechado"
  // a cada nova etapa em vez de continuar aberto por cima da próxima imagem.
  bool _tipOpen = false;

  @override
  Widget build(BuildContext context) {
    final stepInfo = widget.stepInfo;
    final extraNote = widget.extraNote;
    final onDistortion = widget.onDistortion;
    final zoom = widget.zoom;
    final minZoom = widget.minZoom;
    final maxZoom = widget.maxZoom;
    final onZoom = widget.onZoom;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black87],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => setState(() => _tipOpen = !_tipOpen),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _tipOpen
                            ? Icons.lightbulb
                            : Icons.lightbulb_outline,
                        size: 16,
                        color: Colors.amberAccent,
                      ),
                      const SizedBox(width: 6),
                      Text('Dica · ${stepInfo.shortLabel}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Icon(
                        _tipOpen ? Icons.expand_less : Icons.expand_more,
                        size: 16,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_tipOpen) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stepInfo.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(stepInfo.instruction,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                  if (stepInfo.opticalNote != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            size: 14, color: Colors.amberAccent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(stepInfo.opticalNote!,
                              style: const TextStyle(
                                  color: Colors.amberAccent, fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                  if (extraNote != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.priority_high_rounded,
                            size: 14, color: Color(0xFFF4C95D)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(extraNote,
                              style: const TextStyle(
                                  color: Color(0xFFF4C95D), fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                  if (onDistortion != null) ...[
                    const SizedBox(height: 2),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: onDistortion,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                        ),
                        child: const Text('Há deformação? Saiba como testar',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (maxZoom > minZoom)
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.zoom_out, color: Colors.white70, size: 18),
                  Expanded(
                    child: Slider(
                      value: zoom.clamp(minZoom, maxZoom),
                      min: minZoom,
                      max: maxZoom,
                      onChanged: onZoom,
                    ),
                  ),
                  const Icon(Icons.zoom_in, color: Colors.white70, size: 18),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _RoundIconButton(
                  icon: widget.frozen ? Icons.play_arrow : Icons.pause,
                  onTap: widget.onFreeze),
              _RoundIconButton(
                  icon: Icons.add_circle_outline, onTap: widget.onAddCircle),
              _RoundIconButton(icon: Icons.tune, onTap: widget.onEditCircles),
              GestureDetector(
                onTap: widget.onCapture,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Colors.white),
                  ),
                ),
              ),
              _TorchButton(onTorch: widget.onTorch),
              const SizedBox(width: 4),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.isFirstStep ? null : widget.onPrevStep,
                  child: const Text('Voltar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: widget.onNextStep,
                  child: Text(widget.nextLabel,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TorchButton extends StatefulWidget {
  final ValueChanged<bool> onTorch;

  const _TorchButton({required this.onTorch});

  @override
  State<_TorchButton> createState() => _TorchButtonState();
}

class _TorchButtonState extends State<_TorchButton> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    return _RoundIconButton(
      icon: _on ? Icons.flash_on : Icons.flash_off,
      active: _on,
      onTap: () {
        setState(() => _on = !_on);
        widget.onTorch(_on);
      },
    );
  }
}
