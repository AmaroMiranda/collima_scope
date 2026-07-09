enum CalibrationMethod { none, manualAspectCheck, chessboard, circularPattern }

/// Perfil de calibração da câmera (spec §11).
/// No MVP: `distortionCorrectionEnabled = false` e
/// `calibrationMethod = manualAspectCheck`.
class CameraCalibrationProfile {
  final String id;
  final String deviceModel;
  final String cameraLensId;
  final double previewWidth;
  final double previewHeight;
  final double imageWidth;
  final double imageHeight;
  final bool distortionCorrectionEnabled;
  final CalibrationMethod calibrationMethod;
  final bool mainCameraConfirmed;
  final DateTime createdAt;

  const CameraCalibrationProfile({
    required this.id,
    required this.deviceModel,
    required this.cameraLensId,
    required this.previewWidth,
    required this.previewHeight,
    required this.imageWidth,
    required this.imageHeight,
    this.distortionCorrectionEnabled = false,
    this.calibrationMethod = CalibrationMethod.manualAspectCheck,
    this.mainCameraConfirmed = true,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'deviceModel': deviceModel,
        'cameraLensId': cameraLensId,
        'previewWidth': previewWidth,
        'previewHeight': previewHeight,
        'imageWidth': imageWidth,
        'imageHeight': imageHeight,
        'distortionCorrectionEnabled': distortionCorrectionEnabled,
        'calibrationMethod': calibrationMethod.name,
        'mainCameraConfirmed': mainCameraConfirmed,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CameraCalibrationProfile.fromJson(Map<String, dynamic> json) =>
      CameraCalibrationProfile(
        id: json['id'] as String,
        deviceModel: json['deviceModel'] as String,
        cameraLensId: json['cameraLensId'] as String,
        previewWidth: (json['previewWidth'] as num).toDouble(),
        previewHeight: (json['previewHeight'] as num).toDouble(),
        imageWidth: (json['imageWidth'] as num).toDouble(),
        imageHeight: (json['imageHeight'] as num).toDouble(),
        distortionCorrectionEnabled:
            json['distortionCorrectionEnabled'] as bool,
        calibrationMethod:
            CalibrationMethod.values.byName(json['calibrationMethod'] as String),
        mainCameraConfirmed: json['mainCameraConfirmed'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
