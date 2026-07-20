import '../../collimation/domain/collimation_workflow.dart'
    show CollimationStep;
import '../../collimation/domain/guides.dart';

enum CollimationMode {
  visualReference,
  manualAssisted,
  adapterCalibrated, // identificador legado; na prática = alinhamento manual
  automaticExperimental,
}

extension CollimationModeLabel on CollimationMode {
  /// Rótulos honestos (auditoria P0.2): "calibrado" fica reservado para uma
  /// futura calibração medida — hoje o melhor estado é o alinhamento manual.
  String get label => switch (this) {
        CollimationMode.visualReference => 'Referência visual',
        CollimationMode.manualAssisted => 'Assistido · adaptador sem alinhamento',
        CollimationMode.adapterCalibrated =>
          'Assistido · alinhamento manual do adaptador',
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

  /// Guias de TODAS as etapas visitadas (auditoria P2.1) — sem isto o
  /// histórico não consegue reconstruir como cada etapa foi ajustada.
  /// [guides] permanece como a lista da última etapa, para compatibilidade.
  final Map<CollimationStep, List<CollimationGuide>> guidesByStep;
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
    this.guidesByStep = const {},
    this.notes,
  });

  CollimationSession copyWith({
    DateTime? finishedAt,
    CollimationMode? mode,
    String? beforeImagePath,
    String? afterImagePath,
    List<CollimationGuide>? guides,
    Map<CollimationStep, List<CollimationGuide>>? guidesByStep,
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
        guidesByStep: guidesByStep ?? this.guidesByStep,
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
        'guidesByStep': guidesByStep.map(
          (step, list) =>
              MapEntry(step.name, list.map((g) => g.toJson()).toList()),
        ),
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
        guidesByStep: _guidesByStepFromJson(json['guidesByStep']),
        notes: json['notes'] as String?,
      );

  static Map<CollimationStep, List<CollimationGuide>> _guidesByStepFromJson(
      Object? raw) {
    if (raw is! Map<String, dynamic>) return const {};
    final result = <CollimationStep, List<CollimationGuide>>{};
    for (final entry in raw.entries) {
      final step = CollimationStep.values
          .where((s) => s.name == entry.key)
          .firstOrNull;
      if (step == null) continue; // etapa desconhecida (versão futura)
      result[step] = (entry.value as List<dynamic>)
          .map((g) => CollimationGuide.fromJson(g as Map<String, dynamic>))
          .toList();
    }
    return result;
  }
}
