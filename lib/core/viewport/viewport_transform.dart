import 'dart:math' as math;
import 'dart:ui';

import '../geometry/point2d.dart';

/// Mapeia coordenadas entre os espaços do sensor, do preview e do widget,
/// garantindo que o overlay viva exatamente no mesmo espaço visual da câmera.
///
/// Regra crítica: a escala é SEMPRE uniforme (mesmo fator em X e Y).
/// É isso que garante que um círculo desenhado sobre o preview continue
/// sendo um círculo perfeito em qualquer orientação ou resolução.
class ViewportTransform {
  /// Tamanho nativo reportado pelo sensor/stream da câmera.
  final Size sensorSize;

  /// Tamanho do preview já orientado (landscape/portrait resolvido).
  final Size previewSize;

  /// Tamanho do widget que exibe o preview.
  final Size widgetSize;

  /// Região do preview efetivamente visível dentro do widget
  /// (em coordenadas do preview), considerando o crop de BoxFit.cover
  /// ou a área letterboxed de BoxFit.contain.
  final Rect visiblePreviewRect;

  /// Fator de escala uniforme preview -> widget.
  final double scale;

  /// Deslocamento do preview dentro do widget (em pixels do widget).
  final Offset offset;

  /// Rotação aplicada ao sensor para chegar ao preview orientado.
  final int rotationDegrees;

  const ViewportTransform({
    required this.sensorSize,
    required this.previewSize,
    required this.widgetSize,
    required this.visiblePreviewRect,
    required this.scale,
    required this.offset,
    required this.rotationDegrees,
  });

  /// Constrói o transform para um preview exibido com aspecto preservado.
  ///
  /// [cover] = true corta o excesso (tela cheia sem distorção);
  /// [cover] = false mostra o preview inteiro com barras (contain).
  /// Em ambos os casos a escala é uniforme — nunca há achatamento.
  factory ViewportTransform.fit({
    required Size sensorSize,
    required Size previewSize,
    required Size widgetSize,
    int rotationDegrees = 0,
    bool cover = true,
  }) {
    final scaleX = widgetSize.width / previewSize.width;
    final scaleY = widgetSize.height / previewSize.height;
    final scale = cover ? math.max(scaleX, scaleY) : math.min(scaleX, scaleY);

    // Tamanho do preview escalado dentro do widget.
    final scaledW = previewSize.width * scale;
    final scaledH = previewSize.height * scale;
    final offset = Offset(
      (widgetSize.width - scaledW) / 2,
      (widgetSize.height - scaledH) / 2,
    );

    // Região do preview visível (coordenadas do preview).
    final visibleW = math.min(previewSize.width, widgetSize.width / scale);
    final visibleH = math.min(previewSize.height, widgetSize.height / scale);
    final visiblePreviewRect = Rect.fromLTWH(
      (previewSize.width - visibleW) / 2,
      (previewSize.height - visibleH) / 2,
      visibleW,
      visibleH,
    );

    return ViewportTransform(
      sensorSize: sensorSize,
      previewSize: previewSize,
      widgetSize: widgetSize,
      visiblePreviewRect: visiblePreviewRect,
      scale: scale,
      offset: offset,
      rotationDegrees: rotationDegrees,
    );
  }

  /// Retângulo do widget onde o preview visível é desenhado.
  Rect get visibleWidgetRect => Rect.fromLTWH(
        math.max(0, offset.dx),
        math.max(0, offset.dy),
        math.min(widgetSize.width, previewSize.width * scale),
        math.min(widgetSize.height, previewSize.height * scale),
      );

  /// Centro visual do preview em coordenadas do widget.
  Offset get visibleCenter => visibleWidgetRect.center;

  /// Menor lado da área visível — base para raios relativos.
  double get shortestVisibleSide =>
      math.min(visibleWidgetRect.width, visibleWidgetRect.height);

  // ----- Conversões widget <-> preview -----

  Offset screenToPreview(Offset point) => Offset(
        (point.dx - offset.dx) / scale,
        (point.dy - offset.dy) / scale,
      );

  Offset previewToScreen(Offset point) => Offset(
        point.dx * scale + offset.dx,
        point.dy * scale + offset.dy,
      );

  // ----- Conversões widget <-> sensor -----

  Offset screenToSensor(Offset point) {
    final p = screenToPreview(point);
    return _rotate(p, previewSize, -rotationDegrees, sensorSize);
  }

  Offset sensorToScreen(Offset point) {
    final p = _rotate(point, sensorSize, rotationDegrees, previewSize);
    return previewToScreen(p);
  }

  Rect sensorRectToScreen(Rect rect) {
    final a = sensorToScreen(rect.topLeft);
    final b = sensorToScreen(rect.bottomRight);
    return Rect.fromPoints(a, b);
  }

  // ----- Conversões normalizado <-> widget -----

  /// Coordenada normalizada (relativa à área visível do preview) -> widget.
  Offset normalizedToScreen(Point2D point) {
    final r = visibleWidgetRect;
    return Offset(r.left + point.x * r.width, r.top + point.y * r.height);
  }

  Point2D screenToNormalized(Offset point) {
    final r = visibleWidgetRect;
    if (r.width == 0 || r.height == 0) return Point2D.center;
    return Point2D(
      (point.dx - r.left) / r.width,
      (point.dy - r.top) / r.height,
    );
  }

  /// Raio relativo (fração do menor lado visível) -> pixels do widget.
  double normalizedRadiusToScreen(double radius) =>
      radius * shortestVisibleSide;

  double screenRadiusToNormalized(double radiusPx) =>
      shortestVisibleSide == 0 ? 0 : radiusPx / shortestVisibleSide;

  static Offset _rotate(Offset p, Size from, int degrees, Size to) {
    final d = ((degrees % 360) + 360) % 360;
    switch (d) {
      case 90:
        return Offset(from.height - p.dy, p.dx);
      case 180:
        return Offset(from.width - p.dx, from.height - p.dy);
      case 270:
        return Offset(p.dy, from.width - p.dx);
      default:
        return p;
    }
  }
}
