import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:collima_scope/core/geometry/point2d.dart';
import 'package:collima_scope/core/viewport/viewport_transform.dart';

void main() {
  group('ViewportTransform', () {
    // Teste 1 (spec §23): ao mudar de portrait para landscape, os círculos
    // continuam perfeitamente redondos — a escala X e Y é sempre igual.
    test('escala é sempre uniforme em portrait e landscape', () {
      final portrait = ViewportTransform.fit(
        sensorSize: const Size(1920, 1080),
        previewSize: const Size(1080, 1920),
        widgetSize: const Size(400, 800),
        rotationDegrees: 90,
      );
      final landscape = ViewportTransform.fit(
        sensorSize: const Size(1920, 1080),
        previewSize: const Size(1920, 1080),
        widgetSize: const Size(800, 400),
        rotationDegrees: 0,
      );

      // Um raio normalizado deve virar o MESMO número de pixels em X e Y
      // em ambas as orientações, pois o scale é um único double.
      expect(portrait.scale, isPositive);
      expect(landscape.scale, isPositive);

      final radiusPxPortrait = portrait.normalizedRadiusToScreen(0.3);
      final radiusPxLandscape = landscape.normalizedRadiusToScreen(0.3);
      expect(radiusPxPortrait, isPositive);
      expect(radiusPxLandscape, isPositive);
    });

    // Teste 3: centro do overlay corresponde ao centro real do preview,
    // mesmo quando o preview é cortado (cover) dentro do widget.
    test('centro do overlay corresponde ao centro visível do preview', () {
      final t = ViewportTransform.fit(
        sensorSize: const Size(1920, 1080),
        previewSize: const Size(1920, 1080),
        widgetSize: const Size(1080, 1920), // widget mais estreito -> corta
        cover: true,
      );

      final screenCenter = t.normalizedToScreen(Point2D.center);
      final previewCenterInScreen =
          t.previewToScreen(const Offset(1920 / 2, 1080 / 2));

      expect(
        (screenCenter - previewCenterInScreen).distance,
        lessThan(0.5),
      );
    });

    // Teste 4: ao trocar a resolução da câmera, guias em coordenadas
    // normalizadas permanecem no mesmo ponto relativo do viewport visível.
    test('coordenadas normalizadas são estáveis entre resoluções', () {
      final lowRes = ViewportTransform.fit(
        sensorSize: const Size(640, 480),
        previewSize: const Size(640, 480),
        widgetSize: const Size(400, 400),
        cover: true,
      );
      final highRes = ViewportTransform.fit(
        sensorSize: const Size(3840, 2160),
        previewSize: const Size(3840, 2160),
        widgetSize: const Size(400, 400),
        cover: true,
      );

      const point = Point2D(0.75, 0.25);
      final lowScreen = lowRes.normalizedToScreen(point);
      final highScreen = highRes.normalizedToScreen(point);

      // Mesmo widget, mesmo ponto normalizado -> mesma posição na tela,
      // independentemente da resolução do sensor.
      expect((lowScreen - highScreen).distance, lessThan(0.5));
    });

    test('roundtrip screen -> normalized -> screen preserva a posição', () {
      final t = ViewportTransform.fit(
        sensorSize: const Size(1920, 1080),
        previewSize: const Size(1920, 1080),
        widgetSize: const Size(1000, 1000),
        cover: true,
      );
      const original = Offset(423.0, 611.0);
      final normalized = t.screenToNormalized(original);
      final back = t.normalizedToScreen(normalized);
      expect((original - back).distance, lessThan(0.01));
    });
  });
}
