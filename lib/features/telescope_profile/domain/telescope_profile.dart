enum TelescopeType { newtonian, dobsonian }

enum FocuserSize { onePointTwentyFive, twoInch, custom }

extension FocuserSizeLabel on FocuserSize {
  String get label => switch (this) {
        FocuserSize.onePointTwentyFive => '1,25"',
        FocuserSize.twoInch => '2"',
        FocuserSize.custom => 'Personalizado',
      };
}

extension TelescopeTypeLabel on TelescopeType {
  String get label => switch (this) {
        TelescopeType.newtonian => 'Newtoniano',
        TelescopeType.dobsonian => 'Dobsoniano',
      };
}

class TelescopeProfile {
  final String id;
  final String name;
  final TelescopeType type;
  final double? apertureMm;
  final double? focalLengthMm;
  final FocuserSize focuserSize;
  final bool hasPrimaryCenterMark;
  final int primaryScrewCount;
  final bool secondaryOffsetAware;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TelescopeProfile({
    required this.id,
    required this.name,
    required this.type,
    this.apertureMm,
    this.focalLengthMm,
    this.focuserSize = FocuserSize.onePointTwentyFive,
    this.hasPrimaryCenterMark = true,
    this.primaryScrewCount = 3,
    this.secondaryOffsetAware = true,
    required this.createdAt,
    required this.updatedAt,
  });

  TelescopeProfile copyWith({
    String? name,
    TelescopeType? type,
    double? apertureMm,
    double? focalLengthMm,
    FocuserSize? focuserSize,
    bool? hasPrimaryCenterMark,
    int? primaryScrewCount,
    bool? secondaryOffsetAware,
    DateTime? updatedAt,
  }) =>
      TelescopeProfile(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        apertureMm: apertureMm ?? this.apertureMm,
        focalLengthMm: focalLengthMm ?? this.focalLengthMm,
        focuserSize: focuserSize ?? this.focuserSize,
        hasPrimaryCenterMark: hasPrimaryCenterMark ?? this.hasPrimaryCenterMark,
        primaryScrewCount: primaryScrewCount ?? this.primaryScrewCount,
        secondaryOffsetAware: secondaryOffsetAware ?? this.secondaryOffsetAware,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'apertureMm': apertureMm,
        'focalLengthMm': focalLengthMm,
        'focuserSize': focuserSize.name,
        'hasPrimaryCenterMark': hasPrimaryCenterMark,
        'primaryScrewCount': primaryScrewCount,
        'secondaryOffsetAware': secondaryOffsetAware,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TelescopeProfile.fromJson(Map<String, dynamic> json) =>
      TelescopeProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        type: TelescopeType.values.byName(json['type'] as String),
        apertureMm: (json['apertureMm'] as num?)?.toDouble(),
        focalLengthMm: (json['focalLengthMm'] as num?)?.toDouble(),
        focuserSize: FocuserSize.values.byName(json['focuserSize'] as String),
        hasPrimaryCenterMark: json['hasPrimaryCenterMark'] as bool,
        primaryScrewCount: json['primaryScrewCount'] as int,
        secondaryOffsetAware: json['secondaryOffsetAware'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
