import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    try {
      final selection = await _engine.initialize();
      setState(() {
        _mainCameraConfirmed = selection.mainCameraConfirmed;
        _initializing = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _initializing = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _engine.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _engine.dispose();
    } else if (state == AppLifecycleState.resumed && !_engine.isReady) {
      _init();
    }
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
            if (!_mainCameraConfirmed)
              Positioned(
                top: 8,
                left: 12,
                right: 12,
                child: _Banner(
                  icon: Icons.warning_amber_rounded,
                  color: scheme.tertiary,
                  text: 'Não foi possível confirmar a lente principal. '
                      'Evite usar a câmera ultrawide para colimação.',
                ),
              ),
            Positioned(
              top: _mainCameraConfirmed ? 8 : 48,
              left: 12,
              right: 12,
              child: _TopBar(
                stepLabel:
                    '${collimation.stepIndex + 1}/${CollimationWorkflowEngine.steps.length} · ${stepInfo.shortLabel}',
                onClose: () => context.go('/'),
                onReset: controller.resetStepGuides,
                onStepTap: () => _openStepPicker(collimation, controller),
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
                      isFirstStep: collimation.isFirstStep,
                      isLastStep: collimation.isLastStep,
                      onPrevStep: controller.previousStep,
                      onNextStep: () {
                        if (stepInfo.step ==
                            CollimationStep.previewCalibration) {
                          ref
                              .read(previewCalibratedProvider.notifier)
                              .setCalibrated(true);
                        }
                        controller.nextStep();
                      },
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
    final dx = delta.dx / t.shortestVisibleSide;
    final dy = delta.dy / t.shortestVisibleSide;
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
            isBefore ? 'Imagem "antes" salva.' : 'Imagem "depois" salva.'),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Falha ao capturar: $e')));
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

class _Banner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _Banner({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: const TextStyle(color: Colors.white, fontSize: 12))),
        ],
      ),
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

class _BottomPanel extends StatelessWidget {
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
  final bool isFirstStep;
  final bool isLastStep;
  final VoidCallback onPrevStep;
  final VoidCallback onNextStep;

  const _BottomPanel({
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
    required this.isFirstStep,
    required this.isLastStep,
    required this.onPrevStep,
    required this.onNextStep,
  });

  @override
  Widget build(BuildContext context) {
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
          Container(
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
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
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
              ],
            ),
          ),
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
                  icon: frozen ? Icons.play_arrow : Icons.pause,
                  onTap: onFreeze),
              _RoundIconButton(
                  icon: Icons.add_circle_outline, onTap: onAddCircle),
              _RoundIconButton(icon: Icons.tune, onTap: onEditCircles),
              GestureDetector(
                onTap: onCapture,
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
              _TorchButton(onTorch: onTorch),
              const SizedBox(width: 4),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isFirstStep ? null : onPrevStep,
                  child: const Text('Anterior'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: isLastStep ? null : onNextStep,
                  child: Text(isLastStep ? 'Concluído' : 'Próxima etapa'),
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
