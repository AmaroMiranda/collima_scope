import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:collima_scope/core/camera/camera_engine.dart';
import 'package:collima_scope/core/geometry/point2d.dart';
import 'package:collima_scope/features/collimation/domain/collimation_workflow.dart';
import 'package:collima_scope/features/collimation/domain/guide_style.dart';
import 'package:collima_scope/features/collimation/domain/guides.dart';

void main() {
  group('CircleGuide', () {
    // Teste 5 (spec §23): ao criar círculo, não existe controle de
    // largura/altura separado — apenas centro (Point2D) e raio (double).
    test('modelo expõe apenas centro e raio, nunca largura/altura', () {
      const circle = CircleGuide(
        id: 'c1',
        name: 'Teste',
        style: GuidePresets.greenThin,
        center: Point2D.center,
        radius: 0.3,
      );
      // A própria existência desses campos e a ausência de width/height
      // é garantida em tempo de compilação pela classe CircleGuide.
      expect(circle.center, Point2D.center);
      expect(circle.radius, 0.3);
    });

    test('serialização JSON preserva centro e raio', () {
      const circle = CircleGuide(
        id: 'c1',
        name: 'Teste',
        style: GuidePresets.cyanBright,
        center: Point2D(0.4, 0.6),
        radius: 0.25,
      );
      final json = circle.toJson();
      final restored = CollimationGuide.fromJson(json) as CircleGuide;
      expect(restored.center, circle.center);
      expect(restored.radius, circle.radius);
      expect(restored.style.colorValue, circle.style.colorValue);
    });
  });

  group('CameraEngine.selectMainBackCamera', () {
    // Teste 6: ao abrir o app em aparelho com múltiplas câmeras, o app
    // seleciona a câmera principal (id "0"), não a ultrawide.
    test('escolhe a câmera traseira com id "0" entre múltiplas lentes', () {
      final cameras = [
        _fakeCamera('2', CameraLensDirection.back), // telefoto
        _fakeCamera('0', CameraLensDirection.back), // principal
        _fakeCamera('1', CameraLensDirection.back), // ultrawide
        _fakeCamera('front', CameraLensDirection.front),
      ];
      final selection = CameraEngine.selectMainBackCamera(cameras);
      expect(selection.camera.name, '0');
      expect(selection.mainCameraConfirmed, isTrue);
    });
  });

  group('CollimationWorkflowEngine', () {
    // Teste 7: em modo iniciante, o app não instrui que todos os reflexos
    // devem ficar obrigatoriamente concêntricos — a nota de offset do
    // secundário deve estar presente nas etapas relevantes.
    test('etapas do secundário carregam a nota de offset óptico', () {
      final checkSecondary =
          CollimationWorkflowEngine.info(CollimationStep.checkSecondary);
      final alignSecondary = CollimationWorkflowEngine.info(
          CollimationStep.alignSecondaryToPrimary);

      expect(checkSecondary.opticalNote, kSecondaryOffsetNote);
      expect(alignSecondary.opticalNote, kSecondaryOffsetNote);
      for (final step in CollimationWorkflowEngine.steps) {
        expect(step.instruction, isNot(contains('todos os reflexos')));
      }
    });

    // Teste 8: ao finalizar a colimação, o app recomenda validação em estrela.
    test('última etapa é a validação em estrela', () {
      final steps = CollimationWorkflowEngine.steps;
      expect(steps.last.step, CollimationStep.starTest);
      expect(steps.last.instruction, kStarTestInstruction);
    });
  });
}

CameraDescription _fakeCamera(String name, CameraLensDirection direction) {
  return CameraDescription(
    name: name,
    lensDirection: direction,
    sensorOrientation: 90,
  );
}
