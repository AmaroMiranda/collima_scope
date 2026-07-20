import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/geometry/point2d.dart';
import '../../../core/storage/local_store.dart';
import '../../adapter_profile/domain/adapter_profile.dart';
import '../../history/application/session_providers.dart';
import '../../history/domain/collimation_session.dart';
import '../../telescope_profile/domain/telescope_profile.dart';
import '../domain/collimation_workflow.dart';
import '../domain/guide_style.dart';
import '../domain/guides.dart';

class CollimationState {
  final CollimationStep step;

  /// Guias por etapa — cada etapa mantém seus ajustes durante a sessão.
  final Map<CollimationStep, List<CollimationGuide>> guidesByStep;
  final TelescopeProfile? telescope;
  final AdapterProfile? adapter;
  final String? sessionId;
  final DateTime? startedAt;
  final String? beforeImagePath;
  final String? afterImagePath;
  final String? selectedGuideId;

  const CollimationState({
    this.step = CollimationStep.previewCalibration,
    this.guidesByStep = const {},
    this.telescope,
    this.adapter,
    this.sessionId,
    this.startedAt,
    this.beforeImagePath,
    this.afterImagePath,
    this.selectedGuideId,
  });

  List<CollimationGuide> get guides => guidesByStep[step] ?? const [];

  CollimationGuide? get selectedGuide {
    for (final g in guides) {
      if (g.id == selectedGuideId) return g;
    }
    return null;
  }

  /// Modo de colimação segundo a spec §12/§18.
  CollimationMode get mode {
    if (adapter == null) return CollimationMode.visualReference;
    return adapter!.isValidated
        ? CollimationMode.adapterCalibrated
        : CollimationMode.manualAssisted;
  }

  StepInfo get stepInfo => CollimationWorkflowEngine.info(step);
  int get stepIndex => CollimationWorkflowEngine.indexOf(step);
  bool get isFirstStep => stepIndex == 0;
  bool get isLastStep =>
      stepIndex == CollimationWorkflowEngine.steps.length - 1;

  CollimationState copyWith({
    CollimationStep? step,
    Map<CollimationStep, List<CollimationGuide>>? guidesByStep,
    TelescopeProfile? telescope,
    AdapterProfile? adapter,
    bool clearAdapter = false,
    String? sessionId,
    DateTime? startedAt,
    String? beforeImagePath,
    String? afterImagePath,
    String? selectedGuideId,
    bool clearSelection = false,
  }) =>
      CollimationState(
        step: step ?? this.step,
        guidesByStep: guidesByStep ?? this.guidesByStep,
        telescope: telescope ?? this.telescope,
        adapter: clearAdapter ? null : (adapter ?? this.adapter),
        sessionId: sessionId ?? this.sessionId,
        startedAt: startedAt ?? this.startedAt,
        beforeImagePath: beforeImagePath ?? this.beforeImagePath,
        afterImagePath: afterImagePath ?? this.afterImagePath,
        selectedGuideId:
            clearSelection ? null : (selectedGuideId ?? this.selectedGuideId),
      );
}

class CollimationController extends Notifier<CollimationState> {
  @override
  CollimationState build() => const CollimationState();

  void startSession({
    required TelescopeProfile telescope,
    AdapterProfile? adapter,
    bool advancedMode = false,
  }) {
    // A verificação da imagem NUNCA é pulada por uma flag persistida
    // (auditoria P1.3): trocar de aparelho/lente/zoom invalida qualquer
    // verificação anterior. Só o modo avançado explícito pula, com aviso.
    final firstStep = advancedMode
        ? CollimationStep.centerFocuser
        : CollimationStep.previewCalibration;
    state = CollimationState(
      step: firstStep,
      telescope: telescope,
      adapter: adapter,
      sessionId: newId(),
      startedAt: DateTime.now(),
      guidesByStep: {
        firstStep: CollimationWorkflowEngine.defaultGuides(
          firstStep,
          primaryScrewCount: telescope.primaryScrewCount,
        ),
      },
    );
  }

  void goToStep(CollimationStep step) {
    final guides = Map.of(state.guidesByStep);
    guides.putIfAbsent(
      step,
      () => CollimationWorkflowEngine.defaultGuides(
        step,
        primaryScrewCount: state.telescope?.primaryScrewCount ?? 3,
      ),
    );
    state = state.copyWith(step: step, guidesByStep: guides,
        clearSelection: true);
  }

  void nextStep() {
    final i = state.stepIndex;
    if (i < CollimationWorkflowEngine.steps.length - 1) {
      goToStep(CollimationWorkflowEngine.steps[i + 1].step);
    }
  }

  void previousStep() {
    final i = state.stepIndex;
    if (i > 0) {
      goToStep(CollimationWorkflowEngine.steps[i - 1].step);
    }
  }

  // ----- Edição de guias -----

  void selectGuide(String? id) {
    if (id == null) {
      state = state.copyWith(clearSelection: true);
    } else {
      state = state.copyWith(selectedGuideId: id);
    }
  }

  void updateGuide(CollimationGuide updated) {
    final list = state.guides
        .map((g) => g.id == updated.id ? updated : g)
        .toList(growable: false);
    _setGuides(list);
  }

  void moveGuide(String id, double dx, double dy) {
    final guide = state.guides.where((g) => g.id == id).firstOrNull;
    if (guide == null || guide.locked) return;
    switch (guide) {
      case CircleGuide g:
        updateGuide(g.copyWith(center: g.center.translate(dx, dy).clamped()));
      case CrosshairGuide g:
        updateGuide(g.copyWith(center: g.center.translate(dx, dy).clamped()));
      case ScrewMarkerGuide g:
        updateGuide(g.copyWith(center: g.center.translate(dx, dy).clamped()));
      case SpiderGuide g:
        updateGuide(g.copyWith(center: g.center.translate(dx, dy).clamped()));
      case DiagnosticEllipse g:
        updateGuide(g.copyWith(center: g.center.translate(dx, dy).clamped()));
      case GridGuide _:
        break; // grade não se move
    }
  }

  void resetGuideToCenter(String id) {
    final guide = state.guides.where((g) => g.id == id).firstOrNull;
    if (guide == null) return;
    switch (guide) {
      case CircleGuide g:
        updateGuide(g.copyWith(center: Point2D.center));
      case CrosshairGuide g:
        updateGuide(g.copyWith(center: Point2D.center));
      case ScrewMarkerGuide g:
        updateGuide(g.copyWith(center: Point2D.center));
      case SpiderGuide g:
        updateGuide(g.copyWith(center: Point2D.center));
      case DiagnosticEllipse g:
        updateGuide(g.copyWith(center: Point2D.center));
      case GridGuide _:
        break;
    }
  }

  void duplicateGuide(String id) {
    final guide = state.guides.where((g) => g.id == id).firstOrNull;
    if (guide is! CircleGuide) return;
    final copy = CircleGuide(
      id: newId(),
      name: '${guide.name} (cópia)',
      style: guide.style,
      center: guide.center.translate(0.03, 0.03).clamped(),
      radius: guide.radius,
    );
    _setGuides([...state.guides, copy]);
    state = state.copyWith(selectedGuideId: copy.id);
  }

  void addCircle() {
    final circle = CircleGuide(
      id: newId(),
      name: 'Círculo ${state.guides.whereType<CircleGuide>().length + 1}',
      style: GuidePresets.greenThin,
      center: Point2D.center,
      radius: 0.25,
    );
    _setGuides([...state.guides, circle]);
    state = state.copyWith(selectedGuideId: circle.id);
  }

  void removeGuide(String id) {
    _setGuides(state.guides.where((g) => g.id != id).toList());
    if (state.selectedGuideId == id) {
      state = state.copyWith(clearSelection: true);
    }
  }

  void resetStepGuides() {
    _setGuides(CollimationWorkflowEngine.defaultGuides(
      state.step,
      primaryScrewCount: state.telescope?.primaryScrewCount ?? 3,
    ));
    state = state.copyWith(clearSelection: true);
  }

  void _setGuides(List<CollimationGuide> guides) {
    final map = Map.of(state.guidesByStep);
    map[state.step] = guides;
    state = state.copyWith(guidesByStep: map);
  }

  // ----- Capturas e persistência da sessão -----

  void setBeforeImage(String path) =>
      state = state.copyWith(beforeImagePath: path);

  void setAfterImage(String path) =>
      state = state.copyWith(afterImagePath: path);

  Future<void> saveSession({String? notes, bool finished = false}) async {
    final s = state;
    if (s.sessionId == null || s.telescope == null) return;
    final session = CollimationSession(
      id: s.sessionId!,
      telescopeProfileId: s.telescope!.id,
      adapterProfileId: s.adapter?.id,
      startedAt: s.startedAt ?? DateTime.now(),
      finishedAt: finished ? DateTime.now() : null,
      mode: s.mode,
      beforeImagePath: s.beforeImagePath,
      afterImagePath: s.afterImagePath,
      guides: s.guides,
      // Todas as etapas visitadas, não só a atual (auditoria P2.1).
      guidesByStep: s.guidesByStep,
      notes: notes,
    );
    await ref.read(sessionsProvider.notifier).save(session);
  }
}

final collimationControllerProvider =
    NotifierProvider<CollimationController, CollimationState>(
        CollimationController.new);
