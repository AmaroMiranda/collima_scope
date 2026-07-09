import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// Resultado da seleção de câmera, com aviso quando não foi possível
/// garantir que a lente escolhida é a principal (spec §11).
class CameraSelection {
  final CameraDescription camera;
  final bool mainCameraConfirmed;

  const CameraSelection(this.camera, this.mainCameraConfirmed);
}

/// Envolve o plugin `camera`: seleção da traseira principal, foco,
/// exposição, zoom, lanterna, captura e congelamento de frame.
class CameraEngine {
  CameraController? _controller;
  CameraSelection? _selection;
  bool _frozen = false;

  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _zoom = 1.0;
  double _minExposure = 0.0;
  double _maxExposure = 0.0;
  double _exposure = 0.0;

  CameraController? get controller => _controller;
  CameraSelection? get selection => _selection;
  bool get isReady => _controller?.value.isInitialized ?? false;
  bool get isFrozen => _frozen;
  double get minZoom => _minZoom;
  double get maxZoom => _maxZoom;
  double get zoom => _zoom;
  double get minExposure => _minExposure;
  double get maxExposure => _maxExposure;
  double get exposure => _exposure;

  /// Escolhe a câmera traseira principal.
  ///
  /// O plugin não expõe o tipo de lente, então usamos a heurística mais
  /// segura no Android: a primeira câmera traseira da lista (id "0") é a
  /// principal na esmagadora maioria dos aparelhos. Ultrawide e telefoto
  /// aparecem como ids adicionais. Se houver ambiguidade, sinalizamos
  /// `mainCameraConfirmed = false` para a UI alertar o usuário.
  static CameraSelection selectMainBackCamera(List<CameraDescription> all) {
    final back =
        all.where((c) => c.lensDirection == CameraLensDirection.back).toList();
    if (back.isEmpty) {
      return CameraSelection(all.first, false);
    }
    final byId = List.of(back)
      ..sort((a, b) => a.name.compareTo(b.name));
    final confirmed = back.length == 1 || byId.first.name == '0';
    return CameraSelection(byId.first, confirmed);
  }

  Future<CameraSelection> initialize() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw CameraException('noCamera', 'Nenhuma câmera disponível.');
    }
    final selection = selectMainBackCamera(cameras);
    _selection = selection;

    final controller = CameraController(
      selection.camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup:
          Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888,
    );
    await controller.initialize();

    _minZoom = await controller.getMinZoomLevel();
    _maxZoom = await controller.getMaxZoomLevel();
    _minExposure = await controller.getMinExposureOffset();
    _maxExposure = await controller.getMaxExposureOffset();
    _zoom = 1.0;
    _exposure = 0.0;
    _frozen = false;

    _controller = controller;
    return selection;
  }

  Future<void> setZoom(double value) async {
    final c = _controller;
    if (c == null) return;
    _zoom = value.clamp(_minZoom, _maxZoom);
    await c.setZoomLevel(_zoom);
  }

  Future<void> setExposure(double value) async {
    final c = _controller;
    if (c == null) return;
    _exposure = value.clamp(_minExposure, _maxExposure);
    await c.setExposureOffset(_exposure);
  }

  /// Foco por toque, em coordenadas normalizadas (0..1) do preview.
  Future<void> setFocusPoint(double x, double y) async {
    final c = _controller;
    if (c == null) return;
    final point = Offset(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));
    try {
      await c.setFocusPoint(point);
      await c.setExposurePoint(point);
    } on CameraException catch (e) {
      debugPrint('Foco por toque não suportado: ${e.description}');
    }
  }

  Future<void> setTorch(bool on) async {
    final c = _controller;
    if (c == null) return;
    await c.setFlashMode(on ? FlashMode.torch : FlashMode.off);
  }

  Future<void> setFrozen(bool frozen) async {
    final c = _controller;
    if (c == null) return;
    if (frozen) {
      await c.pausePreview();
    } else {
      await c.resumePreview();
    }
    _frozen = frozen;
  }

  Future<XFile> capture() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      throw CameraException('notReady', 'Câmera não inicializada.');
    }
    final wasFrozen = _frozen;
    if (wasFrozen) await c.resumePreview();
    final file = await c.takePicture();
    if (wasFrozen) await c.pausePreview();
    return file;
  }

  Future<void> dispose() async {
    final c = _controller;
    _controller = null;
    await c?.dispose();
  }
}
