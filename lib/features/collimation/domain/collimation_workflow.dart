import '../../../core/geometry/point2d.dart';
import 'guide_style.dart';
import 'guides.dart';

/// Etapas do fluxo de colimação (spec §15).
///
/// Nomes de exibição seguem a auditoria óptica: "verificar" não é "calibrar",
/// e nenhuma etapa afirma medição que o app ainda não realiza.
enum CollimationStep {
  previewCalibration, // identificador mantido p/ compat de JSON; UI: "Verificar imagem"
  adapterCalibration, // UI: "Alinhar câmera ao focalizador"
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

/// Nota óptica obrigatória (spec §14 / revisão 13.4): offset do secundário.
const kSecondaryOffsetNote =
    'Em alguns telescópios Newtonianos, especialmente os de relação focal '
    'curta, a sombra refletida do secundário pode parecer deslocada mesmo '
    'quando os eixos estão corretamente alinhados. Observe somente as '
    'referências indicadas nesta etapa.';

/// Aviso de segurança solar (revisão 13.3).
const kSafetyWarning =
    'Nunca aponte o telescópio para o Sol sem um filtro solar apropriado, '
    'instalado com segurança na abertura frontal. A observação sem proteção '
    'pode causar danos permanentes à visão e ao equipamento.';

/// Validação em estrela (revisão 13.5).
const kStarTestInstruction =
    'Com o telescópio aclimatado e uma estrela centralizada no campo, use '
    'ampliação alta e desfoque levemente para dentro e para fora. O padrão '
    'deve permanecer simétrico ao redor do centro. Recentralize a estrela '
    'após cada ajuste.';

/// Advertência da etapa do primário (auditoria P0.3): a mira digital sozinha
/// não substitui uma referência física centrada no focalizador.
const kPrimaryPhysicalReferenceNote =
    'Para maior precisão, use uma tampa de colimação, Cheshire ou outra '
    'referência física centrada no focalizador. A mira digital isolada é '
    'apenas uma referência aproximada.';

/// Controla etapas, textos e guias padrão de cada etapa.
/// Não emite instruções ópticas do tipo "gire o parafuso X em Y graus".
class CollimationWorkflowEngine {
  static const steps = <StepInfo>[
    StepInfo(
      step: CollimationStep.previewCalibration,
      title: 'Verificar imagem da câmera',
      shortLabel: 'Imagem',
      objective:
          'Identificar deformações visíveis antes de usar as guias.',
      instruction:
          'Confirme se a borda circular usada como referência aparece '
          'regular e sem deformação visível, em pé e deitado. Esta '
          'verificação não substitui uma calibração geométrica medida.',
    ),
    StepInfo(
      step: CollimationStep.adapterCalibration,
      title: 'Alinhar câmera ao focalizador',
      shortLabel: 'Alinhamento',
      objective:
          'Reduzir o deslocamento e a inclinação da câmera em relação ao '
          'eixo do focalizador.',
      instruction:
          'Encaixe o celular no adaptador e ajuste até a mira central '
          'coincidir com o centro do tubo do focalizador. Este alinhamento '
          'é manual: o aplicativo ainda não mede o erro residual.',
    ),
    StepInfo(
      step: CollimationStep.centerFocuser,
      title: 'Centralizar a referência do focalizador',
      shortLabel: 'Focalizador',
      objective:
          'Fazer a borda do focalizador coincidir com a guia na imagem.',
      instruction:
          'Ajuste o círculo do focalizador até coincidir com a borda '
          'interna do tubo. Isso centraliza a referência da imagem — não '
          'garante, sozinho, o eixo óptico.',
    ),
    StepInfo(
      step: CollimationStep.checkSecondary,
      title: 'Posicionar o secundário',
      shortLabel: 'Secundário',
      objective:
          'Posicionar o secundário sob o focalizador: posição longitudinal, '
          'posição lateral e rotação.',
      instruction:
          'Faça a borda visível do secundário coincidir com a guia amarela. '
          'Trate separadamente a posição (deslocar o espelho) e a rotação '
          '(girar o suporte); não use a inclinação para corrigir posição.',
      opticalNote: kSecondaryOffsetNote,
    ),
    StepInfo(
      step: CollimationStep.alignSecondaryToPrimary,
      title: 'Secundário → primário',
      shortLabel: 'Secundário → primário',
      objective:
          'Direcionar o eixo do focalizador para a marca central do '
          'primário, inclinando o secundário.',
      instruction:
          'Ajuste apenas a inclinação do secundário até o espelho primário '
          'inteiro aparecer no círculo, com a marca central sobre a mira. '
          'Se a posição parecer errada, volte à etapa anterior.',
      opticalNote: kSecondaryOffsetNote,
    ),
    StepInfo(
      step: CollimationStep.adjustPrimary,
      title: 'Ajustar primário',
      shortLabel: 'Primário',
      objective: 'Ajustar o eixo óptico do espelho primário.',
      instruction:
          'Use os parafusos de colimação do primário até o reflexo da marca '
          'central coincidir com a referência. Faça ajustes pequenos e '
          'observe a direção do movimento.',
      opticalNote: kPrimaryPhysicalReferenceNote,
    ),
    StepInfo(
      step: CollimationStep.starTest,
      title: 'Validação em estrela',
      shortLabel: 'Estrela',
      objective: 'Confirmar a colimação no céu.',
      instruction: kStarTestInstruction,
      opticalNote:
          'As referências de simetria são apenas apoio visual aproximado — '
          'não representam as dimensões reais dos anéis de difração.',
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
            name: 'Círculo de referência',
            style: GuidePresets.cyanBright,
            center: Point2D.center,
            radius: 0.35,
          ),
          const GridGuide(
            id: 'grid',
            name: 'Grade de apoio',
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
            name: 'Círculo do focalizador',
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
            name: 'Círculo do focalizador',
            style: GuidePresets.cyanBright,
            center: Point2D.center,
            radius: 0.42,
          ),
          const GridGuide(
            id: 'grid',
            name: 'Grade de apoio',
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
            name: 'Círculo do focalizador',
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
            name: 'Referência concêntrica interna',
            style: GuidePresets.greenThin,
            center: Point2D.center,
            radius: 0.2,
          ),
          const CircleGuide(
            id: 'ring-2',
            name: 'Referência concêntrica externa',
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
            name: 'Referência de simetria interna',
            style: GuidePresets.whiteMedium,
            center: Point2D.center,
            radius: 0.1,
          ),
          const CircleGuide(
            id: 'star-ring-2',
            name: 'Referência de simetria externa',
            style: GuidePresets.whiteMedium,
            center: Point2D.center,
            radius: 0.18,
          ),
        ];
    }
  }
}
