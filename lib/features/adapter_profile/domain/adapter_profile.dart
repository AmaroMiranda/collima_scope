import '../../telescope_profile/domain/telescope_profile.dart'
    show FocuserSize;

enum PhoneMountType { generic, printed3D, adjustable, custom }

extension PhoneMountTypeLabel on PhoneMountType {
  String get label => switch (this) {
        PhoneMountType.generic => 'Suporte genérico',
        PhoneMountType.printed3D => 'Impresso em 3D',
        PhoneMountType.adjustable => 'Ajustável',
        PhoneMountType.custom => 'Personalizado',
      };
}

class AdapterProfile {
  final String id;
  final String name;
  final FocuserSize focuserSize;
  final PhoneMountType phoneMountType;

  /// Deslocamento residual da câmera em relação ao eixo do focalizador,
  /// em coordenadas normalizadas (-0.5 a 0.5). Medido na calibração.
  final double cameraOffsetX;
  final double cameraOffsetY;
  final double? tiltX;
  final double? tiltY;
  final DateTime? validatedAt;

  const AdapterProfile({
    required this.id,
    required this.name,
    this.focuserSize = FocuserSize.onePointTwentyFive,
    this.phoneMountType = PhoneMountType.generic,
    this.cameraOffsetX = 0,
    this.cameraOffsetY = 0,
    this.tiltX,
    this.tiltY,
    this.validatedAt,
  });

  bool get isValidated => validatedAt != null;

  AdapterProfile copyWith({
    String? name,
    FocuserSize? focuserSize,
    PhoneMountType? phoneMountType,
    double? cameraOffsetX,
    double? cameraOffsetY,
    double? tiltX,
    double? tiltY,
    DateTime? validatedAt,
    bool clearValidation = false,
  }) =>
      AdapterProfile(
        id: id,
        name: name ?? this.name,
        focuserSize: focuserSize ?? this.focuserSize,
        phoneMountType: phoneMountType ?? this.phoneMountType,
        cameraOffsetX: cameraOffsetX ?? this.cameraOffsetX,
        cameraOffsetY: cameraOffsetY ?? this.cameraOffsetY,
        tiltX: tiltX ?? this.tiltX,
        tiltY: tiltY ?? this.tiltY,
        validatedAt: clearValidation ? null : (validatedAt ?? this.validatedAt),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'focuserSize': focuserSize.name,
        'phoneMountType': phoneMountType.name,
        'cameraOffsetX': cameraOffsetX,
        'cameraOffsetY': cameraOffsetY,
        'tiltX': tiltX,
        'tiltY': tiltY,
        'validatedAt': validatedAt?.toIso8601String(),
      };

  factory AdapterProfile.fromJson(Map<String, dynamic> json) => AdapterProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        focuserSize: FocuserSize.values.byName(json['focuserSize'] as String),
        phoneMountType:
            PhoneMountType.values.byName(json['phoneMountType'] as String),
        cameraOffsetX: (json['cameraOffsetX'] as num).toDouble(),
        cameraOffsetY: (json['cameraOffsetY'] as num).toDouble(),
        tiltX: (json['tiltX'] as num?)?.toDouble(),
        tiltY: (json['tiltY'] as num?)?.toDouble(),
        validatedAt: json['validatedAt'] == null
            ? null
            : DateTime.parse(json['validatedAt'] as String),
      );
}
