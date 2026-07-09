import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../core/viewport/viewport_transform.dart';
import '../../../shared/painters/guide_painter.dart';
import '../domain/guides.dart';

/// Viewport da câmera: preview com escala uniforme (BoxFit.cover manual)
/// + overlay desenhado exatamente no mesmo espaço visual.
///
/// A escala é sempre a MESMA em X e Y — o preview nunca é esticado
/// (spec §5.2/§6). O [ViewportTransform] calculado aqui é entregue ao
/// overlay e aos gestos, garantindo um único sistema de coordenadas.
class CollimationCameraViewport extends StatelessWidget {
  final CameraController controller;
  final List<CollimationGuide> guides;
  final String? highlightedGuideId;
  final ValueChanged<ViewportTransform>? onTransform;

  const CollimationCameraViewport({
    super.key,
    required this.controller,
    required this.guides,
    this.highlightedGuideId,
    this.onTransform,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final widgetSize = Size(constraints.maxWidth, constraints.maxHeight);
        final raw = controller.value.previewSize ?? const Size(1280, 720);

        // O plugin reporta o preview em landscape; orienta para a tela.
        final portrait =
            MediaQuery.of(context).orientation == Orientation.portrait;
        final oriented = portrait
            ? Size(raw.shortestSide, raw.longestSide)
            : Size(raw.longestSide, raw.shortestSide);

        final transform = ViewportTransform.fit(
          sensorSize: raw,
          previewSize: oriented,
          widgetSize: widgetSize,
          rotationDegrees: portrait ? 90 : 0,
          cover: true,
        );
        onTransform?.call(transform);

        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              OverflowBox(
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                child: SizedBox(
                  width: oriented.width * transform.scale,
                  height: oriented.height * transform.scale,
                  child: CameraPreview(controller),
                ),
              ),
              CustomPaint(
                painter: GuidePainter(
                  transform: transform,
                  guides: guides,
                  highlightedGuideId: highlightedGuideId,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
