enum LineStyle { solid, dashed }

/// Estilo visual de uma guia. Não contém geometria — apenas aparência.
class GuideStyle {
  final int colorValue;
  final double strokeWidth;
  final double opacity;
  final LineStyle lineStyle;

  const GuideStyle({
    required this.colorValue,
    this.strokeWidth = 2.0,
    this.opacity = 1.0,
    this.lineStyle = LineStyle.solid,
  });

  GuideStyle copyWith({
    int? colorValue,
    double? strokeWidth,
    double? opacity,
    LineStyle? lineStyle,
  }) =>
      GuideStyle(
        colorValue: colorValue ?? this.colorValue,
        strokeWidth: strokeWidth ?? this.strokeWidth,
        opacity: opacity ?? this.opacity,
        lineStyle: lineStyle ?? this.lineStyle,
      );

  Map<String, dynamic> toJson() => {
        'colorValue': colorValue,
        'strokeWidth': strokeWidth,
        'opacity': opacity,
        'lineStyle': lineStyle.name,
      };

  factory GuideStyle.fromJson(Map<String, dynamic> json) => GuideStyle(
        colorValue: json['colorValue'] as int,
        strokeWidth: (json['strokeWidth'] as num).toDouble(),
        opacity: (json['opacity'] as num).toDouble(),
        lineStyle: LineStyle.values.byName(json['lineStyle'] as String),
      );
}

/// Presets da spec §10.
class GuidePresets {
  static const greenThin =
      GuideStyle(colorValue: 0xFF34D17B, strokeWidth: 1.5);
  static const redThin = GuideStyle(colorValue: 0xFFE0483E, strokeWidth: 1.5);
  static const whiteMedium =
      GuideStyle(colorValue: 0xFFFFFFFF, strokeWidth: 2.5);
  static const yellowDashed = GuideStyle(
      colorValue: 0xFFF2C74B, strokeWidth: 2.0, lineStyle: LineStyle.dashed);
  static const cyanBright =
      GuideStyle(colorValue: 0xFF37E2E2, strokeWidth: 2.0);
  static const nightRed = GuideStyle(
      colorValue: 0xFFB33A2B, strokeWidth: 2.0, opacity: 0.85);

  static const all = <String, GuideStyle>{
    'Verde fino': greenThin,
    'Vermelho fino': redThin,
    'Branco médio': whiteMedium,
    'Amarelo tracejado': yellowDashed,
    'Ciano brilhante': cyanBright,
    'Vermelho noturno': nightRed,
  };
}
