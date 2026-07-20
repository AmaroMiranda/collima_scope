/// Invariantes introduzidas na refatoração (auditoria P1.1 / P2.1 / P2.2).
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:collima_scope/core/geometry/point2d.dart';
import 'package:collima_scope/core/viewport/viewport_transform.dart';
import 'package:collima_scope/features/collimation/domain/collimation_workflow.dart';
import 'package:collima_scope/features/collimation/domain/guide_style.dart';
import 'package:collima_scope/features/collimation/domain/guides.dart';
import 'package:collima_scope/features/history/domain/collimation_session.dart';

void main() {
  group('Arraste normalizado (P1.1)', () {
    // X é fração da LARGURA e Y da ALTURA da área visível: um delta de tela
    // convertido assim e reaplicado via normalizedToScreen precisa reproduzir
    // exatamente o mesmo delta de tela — em qualquer proporção de viewport.
    for (final (label, widget) in [
      ('16:9 deitado', Size(1600, 900)),
      ('retrato comprido 9:20', Size(450, 1000)),
      ('4:3', Size(800, 600)),
    ]) {
      test('delta do dedo == delta da guia em $label', () {
        final t = ViewportTransform.fit(
          sensorSize: const Size(4000, 3000),
          previewSize: const Size(1920, 1080),
          widgetSize: widget,
          cover: true,
        );
        final rect = t.visibleWidgetRect;
        const start = Point2D(0.4, 0.4);
        const fingerDelta = Offset(37.0, 53.0);

        // Conversão corrigida (por eixo, não pelo menor lado).
        final dx = fingerDelta.dx / rect.width;
        final dy = fingerDelta.dy / rect.height;
        final moved = start.translate(dx, dy);

        final before = t.normalizedToScreen(start);
        final after = t.normalizedToScreen(moved);
        expect((after - before).dx, closeTo(fingerDelta.dx, 1e-6));
        expect((after - before).dy, closeTo(fingerDelta.dy, 1e-6));
      });
    }

    test('divisão pelo menor lado NÃO preserva o delta em tela retangular',
        () {
      // Documenta o bug antigo: a regressão volta se alguém "simplificar".
      final t = ViewportTransform.fit(
        sensorSize: const Size(4000, 3000),
        previewSize: const Size(1920, 1080),
        widgetSize: const Size(1600, 900),
        cover: true,
      );
      final rect = t.visibleWidgetRect;
      const fingerDelta = Offset(40.0, 0.0);
      final wrongDx = fingerDelta.dx / t.shortestVisibleSide; // bug antigo
      final screenDx = wrongDx * rect.width;
      expect((screenDx - fingerDelta.dx).abs() > 1.0, isTrue,
          reason: 'em 16:9 o erro do bug antigo é visível (>1 px)');
    });
  });

  group('Persistência de guias por etapa (P2.1)', () {
    CollimationSession buildSession() => CollimationSession(
          id: 's1',
          telescopeProfileId: 't1',
          startedAt: DateTime.utc(2026, 7, 20, 1, 30),
          mode: CollimationMode.adapterCalibrated,
          guides: const [
            CircleGuide(
              id: 'focuser',
              name: 'Círculo do focalizador',
              style: GuidePresets.cyanBright,
              center: Point2D(0.5, 0.48),
              radius: 0.41,
            ),
          ],
          guidesByStep: const {
            CollimationStep.centerFocuser: [
              CircleGuide(
                id: 'focuser',
                name: 'Círculo do focalizador',
                style: GuidePresets.cyanBright,
                center: Point2D(0.5, 0.48),
                radius: 0.41,
              ),
            ],
            CollimationStep.adjustPrimary: [
              CrosshairGuide(
                id: 'crosshair',
                name: 'Mira central',
                style: GuidePresets.whiteMedium,
                center: Point2D(0.52, 0.5),
              ),
            ],
          },
        );

    test('roundtrip JSON preserva as guias de todas as etapas', () {
      final restored =
          CollimationSession.fromJson(buildSession().toJson());
      expect(restored.guidesByStep.length, 2);
      final focuser = restored
          .guidesByStep[CollimationStep.centerFocuser]!.first as CircleGuide;
      expect(focuser.radius, closeTo(0.41, 1e-9));
      expect(focuser.center.x, closeTo(0.5, 1e-9));
      final cross = restored.guidesByStep[CollimationStep.adjustPrimary]!
          .first as CrosshairGuide;
      expect(cross.center.x, closeTo(0.52, 1e-9));
    });

    test('JSON legado (sem guidesByStep) continua carregando', () {
      final legacy = buildSession().toJson()..remove('guidesByStep');
      final restored = CollimationSession.fromJson(legacy);
      expect(restored.guidesByStep, isEmpty);
      expect(restored.guides, isNotEmpty);
    });

    test('etapa desconhecida no JSON é ignorada sem quebrar', () {
      final json = buildSession().toJson();
      json['guidesByStep'] = <String, dynamic>{
        ...(json['guidesByStep'] as Map),
        'etapaFutura': <dynamic>[],
      };
      final restored = CollimationSession.fromJson(json);
      expect(restored.guidesByStep.length, 2);
    });
  });

  group('Rótulos honestos (P0.2)', () {
    test('nenhum modo se apresenta como "calibrado"', () {
      for (final mode in CollimationMode.values) {
        expect(mode.label.toLowerCase().contains('calibrado'), isFalse,
            reason: '"calibrado" fica reservado para calibração medida');
      }
    });
  });
}
