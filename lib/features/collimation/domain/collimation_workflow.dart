import '../../../core/geometry/point2d.dart';
import 'guide_style.dart';
import 'guides.dart';

/// Etapas do fluxo de colimação (spec §15).
enum CollimationStep {
  previewCalibration,
  adapterCalibration,
  centerFocuser,
  checkSecondary,
  alignSecondaryToPrimary,
  adjustPrimary,
  starTest,
}

class StepInfo {
  final CollimationStep step;
  final String title;
  final String shortLabel;
  final String objective;
  final String instruction;
  final String? opticalNote;

  const StepInfo({
    required this.step,
    required this.title,
    required this.shortLabel,
    required this.objective,
    required this.instruction,
    this.opticalNote,
  });
}

/// Nota óptica obrigatória (spec §14): nem tudo precisa ficar concêntrico.
const kSecondaryOffsetNote =
    'Alguns reflexos podem parecer levemente deslocados em Newtonianos. '
    'Siga a etapa atual e não tente forçar todos os círculos a ficarem '
    'concêntricos ao mesmo tempo.';

const kSafetyWarning =
    'Nunca aponte o telescópio para o Sol sem filtro solar adequado. '
    'Risco de dano permanente à visão e ao equipamento.';

const kStarTestInstruction =
    'Após a colimação visual, teste em uma estrela brilhante, centralizada '
    'no campo, com boa ampliação e telescópio aclimatado. A imagem '
    'desfocada deve ficar simétrica.';

/// Controla etapas, textos e guias padrão de cada etapa.
/// Não emite instruções ópticas do tipo "gire o parafuso X em Y graus".
class CollimationWorkflowEngine {
  static const steps = <StepInfo>[
    StepInfo(
      step: CollimationStep.previewCalibration,
      title: 'Calibração do preview',
      shortLabel: 'Preview',
      objective: 'Confirmar que o preview da câmera não está deformado.',
      instruction:
          'Observe o círculo de teste. Ele deve parecer perfeitamente '
          'redondo na tela, em pé e deitado. Se parecer oval, não continue: '
          'o preview está distorcido.',
    ),
    StepInfo(
      step: CollimationStep.adapterCalibration,
      title: 'Calibração do adaptador',
      shortLabel: 'Adaptador',
      objective: 'Alinhar a câmera do celular com o eixo do focador.',
      instruction:
          'Encaixe o celular no adaptador e ajuste até a mira central '
          'coincidir com o centro do tubo do focador. Salve o perfil do '
          'adaptador quando estiver estável.',
    ),
    StepInfo(
      step: CollimationStep.centerFocuser,
      title: 'Centralizar câmera no focador',
      shortLabel: 'Focador',
      objective: 'Garantir que o app está olhando pelo centro do focador.',
      instruction:
          'Ajuste o círculo do focador até coincidir com a borda interna '
          'do tubo. A mira deve ficar no centro da abertura.',
    ),
    StepInfo(
      step: CollimationStep.checkSecondary,
      title: 'Verificar secundário',
      shortLabel: 'Secundário',
      objective:
          'Posicionar o secundário sob o focador, respeitando a geometria '
          'do telescópio.',
      instruction:
          'O secundário deve ficar corretamente posicionado sob o focador. '
          'Em alguns Newtonianos, pode haver offset aparente.',
      opticalNote: kSecondaryOffsetNote,
    ),
    StepInfo(
      step: CollimationStep.alignSecondaryToPrimary,
      title: 'Alinhar secundário com primário',
      shortLabel: 'Sec→Prim',
      objective: 'Direcionar o eixo do focador para o centro do primário.',
      instruction:
          'Ajuste os parafusos do secundário até o espelho primário inteiro '
          'aparecer no círculo, com a marca central sobre a mira.',
      opticalNote: kSecondaryOffsetNote,
    ),
    StepInfo(
      step: CollimationStep.adjustPrimary,
      title: 'Ajustar primário',
      shortLabel: 'Primário',
      objective: 'Ajustar o eixo óptico do espelho primário.',
      instruction:
          'Use os parafusos de colimação do primário até o reflexo da marca '
          'central coincidir com a mira. Faça ajustes pequenos e observe a '
          'direção do movimento.',
    ),
    StepInfo(
      step: CollimationStep.starTest,
      title: 'Validação em estrela',
      shortLabel: 'Estrela',
      objective: 'Confirmar a colimação no céu.',
      instruction: kStarTestInstruction,
    ),
  ];

  static StepInfo info(CollimationStep step) =>
      steps.firstWhere((s) => s.step == step);

  static int indexOf(CollimationStep step) =>
      steps.indexWhere((s) => s.step == step);

  /// Guias padrão de cada etapa (spec §15). O usuário pode editar depois.
  static List<CollimationGuide> defaultGuides(
    CollimationStep step, {
    int primaryScrewCount = 3,
  }) {
    switch (step) {
      case CollimationStep.previewCalibration:
        return [
          const CircleGuide(
            id: 'test-circle',
            name: 'Círculo de teste',
            style: GuidePresets.cyanBright,
            center: Point2D.center,
            radius: 0.35,
          ),
          const GridGuide(
            id: 'grid',
            name: 'Grade',
            style: GuideStyle(
                colorValue: 0xFFFFFFFF, strokeWidth: 0.8, opacity: 0.25),
            divisions: 6,
          ),
        ];
      case CollimationStep.adapterCalibration:
        return [
          const CrosshairGuide(
            id: 'crosshair',
            name: 'Mira central',
            style: GuidePresets.greenThin,
          ),
          const CircleGuide(
            id: 'focuser',
            name: 'Círculo do focador',
            style: GuidePresets.cyanBright,
            center: Point2D.center,
            radius: 0.4,
          ),
        ];
      case CollimationStep.centerFocuser:
        return [
          const CrosshairGuide(
            id: 'crosshair',
            name: 'Mira central',
            style: GuidePresets.greenThin,
          ),
          const CircleGuide(
            id: 'focuser',
            name: 'Círculo do focador',
            style: GuidePresets.cyanBright,
            center: Point2D.center,
            radius: 0.42,
          ),
          const GridGuide(
            id: 'grid',
            name: 'Grade (opcional)',
            style: GuideStyle(
                colorValue: 0xFFFFFFFF, strokeWidth: 0.8, opacity: 0.2),
            divisions: 6,
            visible: false,
          ),
        ];
      case CollimationStep.checkSecondary:
        return [
          const CircleGuide(
            id: 'focuser',
            name: 'Círculo do focador',
            style: GuidePresets.cyanBright,
            center: Point2D.center,
            radius: 0.44,
          ),
          const CircleGuide(
            id: 'secondary',
            name: 'Guia do secundário',
            style: GuidePresets.yellowDashed,
            center: Point2D.center,
            radius: 0.32,
          ),
          const CrosshairGuide(
            id: 'crosshair',
            name: 'Mira central',
            style: GuidePresets.greenThin,
          ),
        ];
      case CollimationStep.alignSecondaryToPrimary:
        return [
          const CircleGuide(
            id: 'primary',
            name: 'Círculo do primário',
            style: GuidePresets.greenThin,
            center: Point2D.center,
            radius: 0.4,
          ),
          const CrosshairGuide(
            id: 'crosshair',
            name: 'Mira central',
            style: GuidePresets.whiteMedium,
          ),
          const CircleGuide(
            id: 'center-mark',
            name: 'Marca central',
            style: GuidePresets.redThin,
            center: Point2D.center,
            radius: 0.05,
          ),
        ];
      case CollimationStep.adjustPrimary:
        return [
          const CrosshairGuide(
            id: 'crosshair',
            name: 'Mira central',
            style: GuidePresets.whiteMedium,
          ),
          const CircleGuide(
            id: 'center-mark',
            name: 'Círculo da marca central',
            style: GuidePresets.redThin,
            center: Point2D.center,
            radius: 0.05,
          ),
          const CircleGuide(
            id: 'ring-1',
            name: 'Círculo concêntrico 1',
            style: GuidePresets.greenThin,
            center: Point2D.center,
            radius: 0.2,
          ),
          const CircleGuide(
            id: 'ring-2',
            name: 'Círculo concêntrico 2',
            style: GuidePresets.greenThin,
            center: Point2D.center,
            radius: 0.34,
          ),
          ScrewMarkerGuide(
            id: 'screws',
            name: 'Parafusos do primário',
            style: GuidePresets.yellowDashed,
            screwCount: primaryScrewCount,
            radius: 0.44,
          ),
        ];
      case CollimationStep.starTest:
        return [
          const CrosshairGuide(
            id: 'crosshair',
            name: 'Mira central',
            style: GuidePresets.greenThin,
          ),
          const CircleGuide(
            id: 'star-ring-1',
            name: 'Anel de difração 1',
            style: GuidePresets.whiteMedium,
            center: Point2D.center,
            radius: 0.1,
          ),
          const CircleGuide(
            id: 'star-ring-2',
            name: 'Anel de difração 2',
            style: GuidePresets.whiteMedium,
            center: Point2D.center,
            radius: 0.18,
          ),
        ];
    }
  }
}
