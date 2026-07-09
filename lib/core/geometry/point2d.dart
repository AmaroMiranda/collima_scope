/// Ponto em coordenadas normalizadas (0.0 a 1.0) relativas ao viewport
/// visível do preview. Tipo de domínio — não depende de dart:ui.
class Point2D {
  final double x;
  final double y;

  const Point2D(this.x, this.y);

  static const center = Point2D(0.5, 0.5);

  Point2D clamped() => Point2D(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));

  Point2D translate(double dx, double dy) => Point2D(x + dx, y + dy);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  factory Point2D.fromJson(Map<String, dynamic> json) =>
      Point2D((json['x'] as num).toDouble(), (json['y'] as num).toDouble());

  @override
  bool operator ==(Object other) =>
      other is Point2D && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Point2D($x, $y)';
}
