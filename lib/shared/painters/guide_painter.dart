import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/viewport/viewport_transform.dart';
import '../../features/collimation/domain/guide_style.dart';
import '../../features/collimation/domain/guides.dart';

/// Desenha todas as guias sobre o viewport da câmera.
///
/// Regra crítica (spec §6): círculos de colimação usam SEMPRE
/// `canvas.drawCircle` com um único raio em pixels — nunca `drawOval`.
/// A única exceção é [DiagnosticEllipse], ferramenta de diagnóstico.
class GuidePainter extends CustomPainter {
  final ViewportTransform transform;
  final List<CollimationGuide> guides;
  final String? highlightedGuideId;

  const GuidePainter({
    required this.transform,
    required this.guides,
    this.highlightedGuideId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(transform.visibleWidgetRect);
    for (final guide in guides) {
      if (!guide.visible) continue;
      final paint = _paintFor(guide);
      switch (guide) {
        case CircleGuide g:
          _drawCircle(canvas, g, paint);
        case CrosshairGuide g:
          _drawCrosshair(canvas, g, paint);
        case GridGuide g:
          _drawGrid(canvas, g, paint);
        case ScrewMarkerGuide g:
          _drawScrewMarkers(canvas, g, paint);
        case SpiderGuide g:
          _drawSpider(canvas, g, paint);
        case DiagnosticEllipse g:
          _drawDiagnosticEllipse(canvas, g, paint);
      }
    }
    canvas.restore();
  }

  Paint _paintFor(CollimationGuide guide) {
    final highlighted = guide.id == highlightedGuideId;
    return Paint()
      ..color = Color(guide.style.colorValue)
          .withValues(alpha: guide.style.opacity)
      ..strokeWidth =
          guide.style.strokeWidth + (highlighted ? 1.2 : 0.0)
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;
  }

  void _drawCircle(Canvas canvas, CircleGuide g, Paint paint) {
    final center = transform.normalizedToScreen(g.center);
    final radius = transform.normalizedRadiusToScreen(g.radius);
    if (g.style.lineStyle == LineStyle.dashed) {
      _drawDashedCircle(canvas, center, radius, paint);
    } else {
      // Círculo perfeito: centro + raio único. Nunca drawOval aqui.
      canvas.drawCircle(center, radius, paint);
    }
  }

  void _drawDashedCircle(
      Canvas canvas, Offset center, double radius, Paint paint) {
    const dashLength = 8.0;
    const gapLength = 6.0;
    final circumference = 2 * math.pi * radius;
    if (circumference <= 0) return;
    final dashCount =
        math.max(8, (circumference / (dashLength + gapLength)).floor());
    final dashAngle = (dashLength / circumference) * 2 * math.pi;
    final stepAngle = 2 * math.pi / dashCount;
    for (var i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * stepAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  void _drawCrosshair(Canvas canvas, CrosshairGuide g, Paint paint) {
    final center = transform.normalizedToScreen(g.center);
    final arm = transform.normalizedRadiusToScreen(g.armLength);
    _line(canvas, Offset(center.dx - arm, center.dy),
        Offset(center.dx + arm, center.dy), g.style, paint);
    _line(canvas, Offset(center.dx, center.dy - arm),
        Offset(center.dx, center.dy + arm), g.style, paint);
    canvas.drawCircle(center, math.max(1.5, paint.strokeWidth),
        Paint()..color = paint.color);
  }

  void _drawGrid(Canvas canvas, GridGuide g, Paint paint) {
    final r = transform.visibleWidgetRect;
    final n = math.max(2, g.divisions);
    for (var i = 1; i < n; i++) {
      final x = r.left + r.width * i / n;
      final y = r.top + r.height * i / n;
      _line(canvas, Offset(x, r.top), Offset(x, r.bottom), g.style, paint);
      _line(canvas, Offset(r.left, y), Offset(r.right, y), g.style, paint);
    }
  }

  void _drawScrewMarkers(Canvas canvas, ScrewMarkerGuide g, Paint paint) {
    final center = transform.normalizedToScreen(g.center);
    final radius = transform.normalizedRadiusToScreen(g.radius);
    final markerRadius = math.max(6.0, radius * 0.06);
    final fill = Paint()
      ..color = paint.color.withValues(alpha: paint.color.a * 0.25)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < g.screwCount; i++) {
      final angle =
          (g.rotationDegrees * math.pi / 180) + (2 * math.pi * i / g.screwCount);
      final p = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawCircle(p, markerRadius, fill);
      canvas.drawCircle(p, markerRadius, paint);
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(
            color: paint.color,
            fontSize: markerRadius * 1.1,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
          canvas,
          p -
              Offset(textPainter.width / 2, textPainter.height / 2) -
              Offset(0, markerRadius * 2.2));
    }
  }

  void _drawSpider(Canvas canvas, SpiderGuide g, Paint paint) {
    final center = transform.normalizedToScreen(g.center);
    final radius = transform.normalizedRadiusToScreen(g.radius);
    for (var i = 0; i < g.vaneCount; i++) {
      final angle =
          (g.rotationDegrees * math.pi / 180) + (2 * math.pi * i / g.vaneCount);
      final p = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      _line(canvas, center, p, g.style, paint);
    }
  }

  /// Elipse APENAS diagnóstica (spec §9) — não é guia de colimação.
  void _drawDiagnosticEllipse(
      Canvas canvas, DiagnosticEllipse g, Paint paint) {
    final center = transform.normalizedToScreen(g.center);
    final rx = transform.normalizedRadiusToScreen(g.radiusX);
    final ry = transform.normalizedRadiusToScreen(g.radiusY);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(g.rotationDegrees * math.pi / 180);
    canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
        paint);
    canvas.restore();
  }

  void _line(
      Canvas canvas, Offset a, Offset b, GuideStyle style, Paint paint) {
    if (style.lineStyle == LineStyle.solid) {
      canvas.drawLine(a, b, paint);
      return;
    }
    const dash = 8.0;
    const gap = 6.0;
    final total = (b - a).distance;
    if (total <= 0) return;
    final dir = (b - a) / total;
    var covered = 0.0;
    while (covered < total) {
      final end = math.min(covered + dash, total);
      canvas.drawLine(a + dir * covered, a + dir * end, paint);
      covered = end + gap;
    }
  }

  @override
  bool shouldRepaint(GuidePainter oldDelegate) =>
      oldDelegate.transform != transform ||
      oldDelegate.guides != guides ||
      oldDelegate.highlightedGuideId != highlightedGuideId;
}

/// Renderiza as guias sobre uma imagem capturada, usando o MESMO painter
/// e o MESMO sistema de coordenadas do preview — a exportação bate com o
/// que o usuário viu (spec §23, Teste 9).
Future<ui.Image> renderGuidesOnImage(
  ui.Image source,
  List<CollimationGuide> guides,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = Size(source.width.toDouble(), source.height.toDouble());
  canvas.drawImage(source, Offset.zero, Paint());

  // A imagem capturada é o "viewport": escala 1, sem crop.
  final transform = ViewportTransform.fit(
    sensorSize: size,
    previewSize: size,
    widgetSize: size,
    cover: false,
  );
  GuidePainter(transform: transform, guides: guides).paint(canvas, size);

  final picture = recorder.endRecording();
  return picture.toImage(source.width, source.height);
}
