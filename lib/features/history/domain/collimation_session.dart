import '../../collimation/domain/guides.dart';

enum CollimationMode {
  visualReference,
  manualAssisted,
  adapterCalibrated,
  automaticExperimental,
}

extension CollimationModeLabel on CollimationMode {
  String get label => switch (this) {
        CollimationMode.visualReference => 'Referência visual',
        CollimationMode.manualAssisted => 'Manual assistido',
        CollimationMode.adapterCalibrated => 'Adaptador calibrado',
        CollimationMode.automaticExperimental => 'Automático (experimental)',
      };
}

class CollimationSession {
  final String id;
  final String telescopeProfileId;
  final String? adapterProfileId;
  final String? cameraCalibrationProfileId;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final CollimationMode mode;
  final String? beforeImagePath;
  final String? afterImagePath;
  final List<CollimationGuide> guides;
  final String? notes;

  const CollimationSession({
    required this.id,
    required this.telescopeProfileId,
    this.adapterProfileId,
    this.cameraCalibrationProfileId,
    required this.startedAt,
    this.finishedAt,
    required this.mode,
    this.beforeImagePath,
    this.afterImagePath,
    this.guides = const [],
    this.notes,
  });

  CollimationSession copyWith({
    DateTime? finishedAt,
    CollimationMode? mode,
    String? beforeImagePath,
    String? afterImagePath,
    List<CollimationGuide>? guides,
    String? notes,
  }) =>
      CollimationSession(
        id: id,
        telescopeProfileId: telescopeProfileId,
        adapterProfileId: adapterProfileId,
        cameraCalibrationProfileId: cameraCalibrationProfileId,
        startedAt: startedAt,
        finishedAt: finishedAt ?? this.finishedAt,
        mode: mode ?? this.mode,
        beforeImagePath: beforeImagePath ?? this.beforeImagePath,
        afterImagePath: afterImagePath ?? this.afterImagePath,
        guides: guides ?? this.guides,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'telescopeProfileId': telescopeProfileId,
        'adapterProfileId': adapterProfileId,
        'cameraCalibrationProfileId': cameraCalibrationProfileId,
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt?.toIso8601String(),
        'mode': mode.name,
        'beforeImagePath': beforeImagePath,
        'afterImagePath': afterImagePath,
        'guides': guides.map((g) => g.toJson()).toList(),
        'notes': notes,
      };

  factory CollimationSession.fromJson(Map<String, dynamic> json) =>
      CollimationSession(
        id: json['id'] as String,
        telescopeProfileId: json['telescopeProfileId'] as String,
        adapterProfileId: json['adapterProfileId'] as String?,
        cameraCalibrationProfileId:
            json['cameraCalibrationProfileId'] as String?,
        startedAt: DateTime.parse(json['startedAt'] as String),
        finishedAt: json['finishedAt'] == null
            ? null
            : DateTime.parse(json['finishedAt'] as String),
        mode: CollimationMode.values.byName(json['mode'] as String),
        beforeImagePath: json['beforeImagePath'] as String?,
        afterImagePath: json['afterImagePath'] as String?,
        guides: (json['guides'] as List<dynamic>? ?? [])
            .map((g) => CollimationGuide.fromJson(g as Map<String, dynamic>))
            .toList(),
        notes: json['notes'] as String?,
      );
}
