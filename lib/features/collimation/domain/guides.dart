import '../../../core/geometry/point2d.dart';
import 'guide_style.dart';

/// Guias de colimação (spec §9).
///
/// Regra crítica (spec §6): guias principais são círculos perfeitos —
/// apenas centro e raio. Não existe largura/altura nem escala X/Y.
/// A única entidade elíptica é [DiagnosticEllipse], que serve somente
/// para diagnóstico e nunca pode ser usada como referência principal.
sealed class CollimationGuide {
  final String id;
  final String name;
  final GuideStyle style;
  final bool visible;
  final bool locked;

  const CollimationGuide({
    required this.id,
    required this.name,
    required this.style,
    this.visible = true,
    this.locked = false,
  });

  CollimationGuide copyWithCommon({
    String? name,
    GuideStyle? style,
    bool? visible,
    bool? locked,
  });

  Map<String, dynamic> toJson();

  static CollimationGuide fromJson(Map<String, dynamic> json) {
    switch (json['kind'] as String) {
      case 'circle':
        return CircleGuide.fromJson(json);
      case 'crosshair':
        return CrosshairGuide.fromJson(json);
      case 'grid':
        return GridGuide.fromJson(json);
      case 'screwMarkers':
        return ScrewMarkerGuide.fromJson(json);
      case 'spider':
        return SpiderGuide.fromJson(json);
      case 'diagnosticEllipse':
        return DiagnosticEllipse.fromJson(json);
      default:
        throw ArgumentError('Guia desconhecida: ${json['kind']}');
    }
  }

  Map<String, dynamic> _commonJson(String kind) => {
        'kind': kind,
        'id': id,
        'name': name,
        'style': style.toJson(),
        'visible': visible,
        'locked': locked,
      };
}

/// Círculo perfeito: somente centro (normalizado) e raio
/// (fração do menor lado da área visível do viewport).
class CircleGuide extends CollimationGuide {
  final Point2D center;
  final double radius;

  const CircleGuide({
    required super.id,
    required super.name,
    required super.style,
    required this.center,
    required this.radius,
    super.visible,
    super.locked,
  });

  CircleGuide copyWith({
    String? name,
    GuideStyle? style,
    bool? visible,
    bool? locked,
    Point2D? center,
    double? radius,
  }) =>
      CircleGuide(
        id: id,
        name: name ?? this.name,
        style: style ?? this.style,
        visible: visible ?? this.visible,
        locked: locked ?? this.locked,
        center: center ?? this.center,
        radius: radius ?? this.radius,
      );

  @override
  CircleGuide copyWithCommon(
          {String? name, GuideStyle? style, bool? visible, bool? locked}) =>
      copyWith(name: name, style: style, visible: visible, locked: locked);

  @override
  Map<String, dynamic> toJson() => {
        ..._commonJson('circle'),
        'center': center.toJson(),
        'radius': radius,
      };

  factory CircleGuide.fromJson(Map<String, dynamic> json) => CircleGuide(
        id: json['id'] as String,
        name: json['name'] as String,
        style: GuideStyle.fromJson(json['style'] as Map<String, dynamic>),
        visible: json['visible'] as bool,
        locked: json['locked'] as bool,
        center: Point2D.fromJson(json['center'] as Map<String, dynamic>),
        radius: (json['radius'] as num).toDouble(),
      );
}

/// Mira central (duas linhas cruzadas + ponto opcional).
class CrosshairGuide extends CollimationGuide {
  final Point2D center;
  final double armLength; // fração do menor lado

  const CrosshairGuide({
    required super.id,
    required super.name,
    required super.style,
    this.center = Point2D.center,
    this.armLength = 0.12,
    super.visible,
    super.locked,
  });

  CrosshairGuide copyWith({
    String? name,
    GuideStyle? style,
    bool? visible,
    bool? locked,
    Point2D? center,
    double? armLength,
  }) =>
      CrosshairGuide(
        id: id,
        name: name ?? this.name,
        style: style ?? this.style,
        visible: visible ?? this.visible,
        locked: locked ?? this.locked,
        center: center ?? this.center,
        armLength: armLength ?? this.armLength,
      );

  @override
  CrosshairGuide copyWithCommon(
          {String? name, GuideStyle? style, bool? visible, bool? locked}) =>
      copyWith(name: name, style: style, visible: visible, locked: locked);

  @override
  Map<String, dynamic> toJson() => {
        ..._commonJson('crosshair'),
        'center': center.toJson(),
        'armLength': armLength,
      };

  factory CrosshairGuide.fromJson(Map<String, dynamic> json) => CrosshairGuide(
        id: json['id'] as String,
        name: json['name'] as String,
        style: GuideStyle.fromJson(json['style'] as Map<String, dynamic>),
        visible: json['visible'] as bool,
        locked: json['locked'] as bool,
        center: Point2D.fromJson(json['center'] as Map<String, dynamic>),
        armLength: (json['armLength'] as num).toDouble(),
      );
}

/// Grade uniforme sobre a área visível.
class GridGuide extends CollimationGuide {
  final int divisions;

  const GridGuide({
    required super.id,
    required super.name,
    required super.style,
    this.divisions = 6,
    super.visible,
    super.locked,
  });

  GridGuide copyWith({
    String? name,
    GuideStyle? style,
    bool? visible,
    bool? locked,
    int? divisions,
  }) =>
      GridGuide(
        id: id,
        name: name ?? this.name,
        style: style ?? this.style,
        visible: visible ?? this.visible,
        locked: locked ?? this.locked,
        divisions: divisions ?? this.divisions,
      );

  @override
  GridGuide copyWithCommon(
          {String? name, GuideStyle? style, bool? visible, bool? locked}) =>
      copyWith(name: name, style: style, visible: visible, locked: locked);

  @override
  Map<String, dynamic> toJson() =>
      {..._commonJson('grid'), 'divisions': divisions};

  factory GridGuide.fromJson(Map<String, dynamic> json) => GridGuide(
        id: json['id'] as String,
        name: json['name'] as String,
        style: GuideStyle.fromJson(json['style'] as Map<String, dynamic>),
        visible: json['visible'] as bool,
        locked: json['locked'] as bool,
        divisions: json['divisions'] as int,
      );
}

/// Marcadores dos parafusos do primário, distribuídos em um anel.
class ScrewMarkerGuide extends CollimationGuide {
  final Point2D center;
  final double radius; // raio do anel onde ficam os parafusos
  final int screwCount;
  final double rotationDegrees;

  const ScrewMarkerGuide({
    required super.id,
    required super.name,
    required super.style,
    this.center = Point2D.center,
    this.radius = 0.42,
    this.screwCount = 3,
    this.rotationDegrees = 90,
    super.visible,
    super.locked,
  });

  ScrewMarkerGuide copyWith({
    String? name,
    GuideStyle? style,
    bool? visible,
    bool? locked,
    Point2D? center,
    double? radius,
    int? screwCount,
    double? rotationDegrees,
  }) =>
      ScrewMarkerGuide(
        id: id,
        name: name ?? this.name,
        style: style ?? this.style,
        visible: visible ?? this.visible,
        locked: locked ?? this.locked,
        center: center ?? this.center,
        radius: radius ?? this.radius,
        screwCount: screwCount ?? this.screwCount,
        rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      );

  @override
  ScrewMarkerGuide copyWithCommon(
          {String? name, GuideStyle? style, bool? visible, bool? locked}) =>
      copyWith(name: name, style: style, visible: visible, locked: locked);

  @override
  Map<String, dynamic> toJson() => {
        ..._commonJson('screwMarkers'),
        'center': center.toJson(),
        'radius': radius,
        'screwCount': screwCount,
        'rotationDegrees': rotationDegrees,
      };

  factory ScrewMarkerGuide.fromJson(Map<String, dynamic> json) =>
      ScrewMarkerGuide(
        id: json['id'] as String,
        name: json['name'] as String,
        style: GuideStyle.fromJson(json['style'] as Map<String, dynamic>),
        visible: json['visible'] as bool,
        locked: json['locked'] as bool,
        center: Point2D.fromJson(json['center'] as Map<String, dynamic>),
        radius: (json['radius'] as num).toDouble(),
        screwCount: json['screwCount'] as int,
        rotationDegrees: (json['rotationDegrees'] as num).toDouble(),
      );
}

/// Referência das vanes da aranha (4 braços por padrão).
class SpiderGuide extends CollimationGuide {
  final Point2D center;
  final double radius;
  final int vaneCount;
  final double rotationDegrees;

  const SpiderGuide({
    required super.id,
    required super.name,
    required super.style,
    this.center = Point2D.center,
    this.radius = 0.35,
    this.vaneCount = 4,
    this.rotationDegrees = 45,
    super.visible,
    super.locked,
  });

  SpiderGuide copyWith({
    String? name,
    GuideStyle? style,
    bool? visible,
    bool? locked,
    Point2D? center,
    double? radius,
    int? vaneCount,
    double? rotationDegrees,
  }) =>
      SpiderGuide(
        id: id,
        name: name ?? this.name,
        style: style ?? this.style,
        visible: visible ?? this.visible,
        locked: locked ?? this.locked,
        center: center ?? this.center,
        radius: radius ?? this.radius,
        vaneCount: vaneCount ?? this.vaneCount,
        rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      );

  @override
  SpiderGuide copyWithCommon(
          {String? name, GuideStyle? style, bool? visible, bool? locked}) =>
      copyWith(name: name, style: style, visible: visible, locked: locked);

  @override
  Map<String, dynamic> toJson() => {
        ..._commonJson('spider'),
        'center': center.toJson(),
        'radius': radius,
        'vaneCount': vaneCount,
        'rotationDegrees': rotationDegrees,
      };

  factory SpiderGuide.fromJson(Map<String, dynamic> json) => SpiderGuide(
        id: json['id'] as String,
        name: json['name'] as String,
        style: GuideStyle.fromJson(json['style'] as Map<String, dynamic>),
        visible: json['visible'] as bool,
        locked: json['locked'] as bool,
        center: Point2D.fromJson(json['center'] as Map<String, dynamic>),
        radius: (json['radius'] as num).toDouble(),
        vaneCount: json['vaneCount'] as int,
        rotationDegrees: (json['rotationDegrees'] as num).toDouble(),
      );
}

/// Elipse de diagnóstico — NUNCA é guia principal de colimação.
/// Serve apenas para o usuário avaliar visualmente distorções aparentes.
class DiagnosticEllipse extends CollimationGuide {
  final Point2D center;
  final double radiusX;
  final double radiusY;
  final double rotationDegrees;

  const DiagnosticEllipse({
    required super.id,
    required super.name,
    required super.style,
    this.center = Point2D.center,
    this.radiusX = 0.3,
    this.radiusY = 0.2,
    this.rotationDegrees = 0,
    super.visible,
    super.locked,
  });

  DiagnosticEllipse copyWith({
    String? name,
    GuideStyle? style,
    bool? visible,
    bool? locked,
    Point2D? center,
    double? radiusX,
    double? radiusY,
    double? rotationDegrees,
  }) =>
      DiagnosticEllipse(
        id: id,
        name: name ?? this.name,
        style: style ?? this.style,
        visible: visible ?? this.visible,
        locked: locked ?? this.locked,
        center: center ?? this.center,
        radiusX: radiusX ?? this.radiusX,
        radiusY: radiusY ?? this.radiusY,
        rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      );

  @override
  DiagnosticEllipse copyWithCommon(
          {String? name, GuideStyle? style, bool? visible, bool? locked}) =>
      copyWith(name: name, style: style, visible: visible, locked: locked);

  @override
  Map<String, dynamic> toJson() => {
        ..._commonJson('diagnosticEllipse'),
        'center': center.toJson(),
        'radiusX': radiusX,
        'radiusY': radiusY,
        'rotationDegrees': rotationDegrees,
      };

  factory DiagnosticEllipse.fromJson(Map<String, dynamic> json) =>
      DiagnosticEllipse(
        id: json['id'] as String,
        name: json['name'] as String,
        style: GuideStyle.fromJson(json['style'] as Map<String, dynamic>),
        visible: json['visible'] as bool,
        locked: json['locked'] as bool,
        center: Point2D.fromJson(json['center'] as Map<String, dynamic>),
        radiusX: (json['radiusX'] as num).toDouble(),
        radiusY: (json['radiusY'] as num).toDouble(),
        rotationDegrees: (json['rotationDegrees'] as num).toDouble(),
      );
}
