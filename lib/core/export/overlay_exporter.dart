import 'dart:io';
import 'dart:ui' as ui;

import 'package:path_provider/path_provider.dart';

import '../../features/collimation/domain/guides.dart';
import '../../shared/painters/guide_painter.dart';

/// Exporta imagens capturadas, com ou sem overlay, preservando proporção 1:1.
class OverlayExporter {
  /// Copia a captura para o diretório do app e retorna o novo caminho.
  Future<String> persistCapture(String sourcePath, String name) async {
    final dir = await _imagesDir();
    final dest = File('${dir.path}${Platform.pathSeparator}$name.jpg');
    await File(sourcePath).copy(dest.path);
    return dest.path;
  }

  /// Gera um PNG da captura com as guias desenhadas por cima, no mesmo
  /// sistema de coordenadas normalizado usado no preview.
  Future<String> exportWithOverlay(
    String imagePath,
    List<CollimationGuide> guides,
    String name,
  ) async {
    final bytes = await File(imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final source = frame.image;

    final composed = await renderGuidesOnImage(source, guides);
    final data = await composed.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      throw StateError('Falha ao codificar imagem exportada.');
    }

    final dir = await _imagesDir();
    final dest = File('${dir.path}${Platform.pathSeparator}$name.png');
    await dest.writeAsBytes(data.buffer.asUint8List());
    source.dispose();
    composed.dispose();
    return dest.path;
  }

  Future<Directory> _imagesDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}collimascope');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
