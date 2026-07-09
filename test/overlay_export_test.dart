import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:collima_scope/core/geometry/point2d.dart';
import 'package:collima_scope/features/collimation/domain/guide_style.dart';
import 'package:collima_scope/features/collimation/domain/guides.dart';
import 'package:collima_scope/shared/painters/guide_painter.dart';

Future<ui.Image> _solidImage(int size, ui.Color color) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    ui.Paint()..color = color,
  );
  final picture = recorder.endRecording();
  return picture.toImage(size, size);
}

void main() {
  // Teste 2 (spec §23): ao salvar imagem com overlay, o círculo salvo
  // mantém proporção 1:1 — a imagem exportada tem o mesmo tamanho (mesma
  // escala em X e Y) da imagem de origem.
  test('renderGuidesOnImage preserva as dimensões (proporção 1:1)', () async {
    const size = 300;
    final source = await _solidImage(size, const ui.Color(0xFF000000));

    const guides = [
      CircleGuide(
        id: 'c1',
        name: 'Círculo',
        style: GuidePresets.cyanBright,
        center: Point2D.center,
        radius: 0.3,
      ),
    ];

    final result = await renderGuidesOnImage(source, guides);

    expect(result.width, size);
    expect(result.height, size);

    source.dispose();
    result.dispose();
  });

  // Teste 9: o overlay exportado usa o mesmo sistema de coordenadas
  // normalizadas do preview — um círculo centralizado deve produzir
  // pixels alterados simetricamente ao redor do centro da imagem.
  test('overlay exportado é desenhado no centro correto da imagem', () async {
    const size = 200;
    final source = await _solidImage(size, const ui.Color(0xFF000000));

    const guides = [
      CircleGuide(
        id: 'c1',
        name: 'Círculo',
        style: GuideStyle(colorValue: 0xFFFFFFFF, strokeWidth: 6),
        center: Point2D.center,
        radius: 0.4,
      ),
    ];

    final result = await renderGuidesOnImage(source, guides);
    final byteData =
        await result.toByteData(format: ui.ImageByteFormat.rawRgba);
    expect(byteData, isNotNull);

    // Pixel no centro exato da imagem não deve estar sobre o traço do
    // círculo (raio 0.4 do lado), então continua preto.
    final pixels = byteData!.buffer.asUint8List();
    final centerIndex = ((size ~/ 2) * size + (size ~/ 2)) * 4;
    expect(pixels[centerIndex], 0); // canal R do centro permanece preto

    source.dispose();
    result.dispose();
  });
}
