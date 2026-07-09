// Gera o ícone do CollimaScope: mira de colimação com círculos
// concêntricos perfeitos, fiel à identidade visual do app.
// Uso: dart run tool/generate_icon.dart
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

void main() {
  _generate(
    size: 1024,
    fileName: 'assets/icon/icon.png',
    withBackground: true,
  );
  _generate(
    size: 1024,
    fileName: 'assets/icon/icon_foreground.png',
    withBackground: false,
  );
  stdout.writeln('Ícones gerados em assets/icon/.');
}

void _generate({
  required int size,
  required String fileName,
  required bool withBackground,
}) {
  final image = img.Image(width: size, height: size, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));

  final bg = img.ColorRgba8(0x05, 0x07, 0x0D, 255);
  final cyan = img.ColorRgba8(0x37, 0xE2, 0xE2, 255);
  final green = img.ColorRgba8(0x34, 0xD1, 0x7B, 255);
  final white = img.ColorRgba8(0xFF, 0xFF, 0xFF, 255);
  final red = img.ColorRgba8(0xE0, 0x48, 0x3E, 255);

  final center = size / 2;

  if (withBackground) {
    // Fundo com leve gradiente radial escuro, para o ícone legado/adaptativo.
    _fillRoundedSquare(image, bg, cornerRadius: size * 0.22);
  }

  // Zona segura do ícone adaptativo: ~66% central.
  final scale = withBackground ? 1.0 : 0.62;
  final maxRadius = center * 0.86 * scale;

  _strokeCircle(image, center, center, maxRadius, cyan, size * 0.028);
  _strokeCircle(image, center, center, maxRadius * 0.66, green, size * 0.024);
  _strokeCircle(image, center, center, maxRadius * 0.34, white, size * 0.020);

  // Mira central.
  final armOuter = maxRadius * 0.18;
  final armInner = maxRadius * 0.06;
  _thickLine(image, center - armOuter, center, center - armInner, center,
      white, size * 0.018);
  _thickLine(image, center + armInner, center, center + armOuter, center,
      white, size * 0.018);
  _thickLine(image, center, center - armOuter, center, center - armInner,
      white, size * 0.018);
  _thickLine(image, center, center + armInner, center, center + armOuter,
      white, size * 0.018);

  // Ponto central (marca do primário).
  _fillCircle(image, center, center, maxRadius * 0.035, red);

  // Três marcadores de parafuso no anel externo — identidade do produto.
  for (var i = 0; i < 3; i++) {
    final angle = -math.pi / 2 + (2 * math.pi * i / 3);
    final px = center + maxRadius * math.cos(angle);
    final py = center + maxRadius * math.sin(angle);
    _fillCircle(image, px, py, size * 0.02, green);
  }

  File(fileName).writeAsBytesSync(img.encodePng(image));
}

void _fillRoundedSquare(img.Image image, img.Color color,
    {required double cornerRadius}) {
  final w = image.width.toDouble();
  final h = image.height.toDouble();
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (_insideRoundedSquare(x + 0.5, y + 0.5, w, h, cornerRadius)) {
        image.setPixel(x, y, color);
      }
    }
  }
}

bool _insideRoundedSquare(
    double x, double y, double w, double h, double r) {
  final cx = x < r
      ? r
      : (x > w - r ? w - r : x);
  final cy = y < r
      ? r
      : (y > h - r ? h - r : y);
  if (x >= r && x <= w - r) return y >= 0 && y <= h;
  if (y >= r && y <= h - r) return x >= 0 && x <= w;
  final dx = x - cx;
  final dy = y - cy;
  return dx * dx + dy * dy <= r * r;
}

void _strokeCircle(img.Image image, double cx, double cy, double radius,
    img.Color color, double thickness) {
  final outer = radius + thickness / 2;
  final inner = radius - thickness / 2;
  final minX = math.max(0, (cx - outer).floor());
  final maxX = math.min(image.width - 1, (cx + outer).ceil());
  final minY = math.max(0, (cy - outer).floor());
  final maxY = math.min(image.height - 1, (cy + outer).ceil());
  for (var y = minY; y <= maxY; y++) {
    for (var x = minX; x <= maxX; x++) {
      final dx = x + 0.5 - cx;
      final dy = y + 0.5 - cy;
      final d = math.sqrt(dx * dx + dy * dy);
      if (d >= inner && d <= outer) {
        image.setPixel(x, y, color);
      }
    }
  }
}

void _fillCircle(
    img.Image image, double cx, double cy, double radius, img.Color color) {
  final minX = math.max(0, (cx - radius).floor());
  final maxX = math.min(image.width - 1, (cx + radius).ceil());
  final minY = math.max(0, (cy - radius).floor());
  final maxY = math.min(image.height - 1, (cy + radius).ceil());
  for (var y = minY; y <= maxY; y++) {
    for (var x = minX; x <= maxX; x++) {
      final dx = x + 0.5 - cx;
      final dy = y + 0.5 - cy;
      if (dx * dx + dy * dy <= radius * radius) {
        image.setPixel(x, y, color);
      }
    }
  }
}

void _thickLine(img.Image image, double x1, double y1, double x2, double y2,
    img.Color color, double thickness) {
  final dx = x2 - x1;
  final dy = y2 - y1;
  final length = math.sqrt(dx * dx + dy * dy);
  if (length == 0) return;

  final minX = math.max(
      0, (math.min(x1, x2) - thickness).floor());
  final maxX = math.min(
      image.width - 1, (math.max(x1, x2) + thickness).ceil());
  final minY = math.max(
      0, (math.min(y1, y2) - thickness).floor());
  final maxY = math.min(
      image.height - 1, (math.max(y1, y2) + thickness).ceil());

  for (var y = minY; y <= maxY; y++) {
    for (var x = minX; x <= maxX; x++) {
      final px = x + 0.5;
      final py = y + 0.5;
      // Distância do ponto ao segmento de reta.
      final t = (((px - x1) * dx + (py - y1) * dy) / (length * length))
          .clamp(0.0, 1.0);
      final projX = x1 + t * dx;
      final projY = y1 + t * dy;
      final ddx = px - projX;
      final ddy = py - projY;
      final dist = math.sqrt(ddx * ddx + ddy * ddy);
      if (dist <= thickness / 2) {
        image.setPixel(x, y, color);
      }
    }
  }
}
