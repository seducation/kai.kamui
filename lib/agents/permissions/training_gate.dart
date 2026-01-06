import '../core/step_logger.dart';
import '../core/step_types.dart';
import '../core/step_schema.dart';

import 'permission_types.dart';
import 'access_gate.dart';

/// Gate for validating AI model training access.
///
/// This ensures that models can only train on data they have
/// explicit "train" permission for.
class TrainingGate {
  // Singleton
  static final TrainingGate _instance = TrainingGate._internal();
  factory TrainingGate() => _instance;
  TrainingGate._internal();

  final AccessGate _gate = AccessGate();
  final StepLogger _logger = GlobalStepLogger().logger;

  /// Request training access for a model on a dataset.
  ///
  /// Throws [TrainingDeniedException] if access is not granted.
  Future<void> requestTrainingAccess({
    required String model,
    required String datasetPath,
    required String purpose,
  }) async {
    final result = await _gate.requestAccess(
      requester: model,
      requesterType: GranteeType.model,
      resourcePath: datasetPath,
      action: PermissionType.train,
      metadata: {
        'purpose': purpose,
      },
    );

    if (result != AccessResult.allowed) {
      _logger.logStep(
        agentName: 'TrainingGate',
        action: StepType.error,
        target: 'Training access DENIED for $model on $datasetPath',
        status: StepStatus.failed,
        metadata: {
          'model': model,
          'dataset': datasetPath,
          'purpose': purpose,
          'reason': 'No train permission granted',
        },
      );

      throw TrainingDeniedException(
        model: model,
        datasetPath: datasetPath,
        reason: 'No train permission granted for this dataset',
      );
    }

    _logger.logStep(
      agentName: 'TrainingGate',
      action: StepType.check,
      target: 'Training access ALLOWED for $model on $datasetPath',
      status: StepStatus.success,
      metadata: {
        'model': model,
        'dataset': datasetPath,
        'purpose': purpose,
      },
    );
  }

  /// Check if training would be allowed (without logging)
  Future<bool> wouldAllow({
    required String model,
    required String datasetPath,
  }) async {
    return await _gate.canTrain(model, datasetPath);
  }
}

/// Exception thrown when training access is denied.
class TrainingDeniedException implements Exception {
  final String model;
  final String datasetPath;
  final String reason;

  TrainingDeniedException({
    required this.model,
    required this.datasetPath,
    required this.reason,
  });

  @override
  String toString() {
    return 'TrainingDeniedException: $model denied training access to $datasetPath - $reason';
  }
}
