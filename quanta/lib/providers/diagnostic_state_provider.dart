import 'package:flutter/material.dart';
import '../widgets/glassmorphic_clinical_panel.dart';

enum DiseaseDomain { oncology, cardiovascular, neurological, unknown }

class InferenceResult {
  final String patientId;
  final DiseaseDomain domain;
  final ClinicalTriage triage;
  final double confidenceScore;
  final List<double> qutritProbabilities;
  final List<double> classicalProbabilities;
  final String clinicalNarrative;
  final DateTime timestamp;

  InferenceResult({
    required this.patientId,
    required this.domain,
    required this.triage,
    required this.confidenceScore,
    required this.qutritProbabilities,
    required this.classicalProbabilities,
    required this.clinicalNarrative,
    required this.timestamp,
  });
}

class PatientDiagnosticContext {
  final String patientId;
  final DiseaseDomain domain;
  final String? fileName;
  
  // Pipeline Hyperparameters
  final double epochs;
  final double layers;
  final String diagnosticProfile;

  PatientDiagnosticContext({
    required this.patientId,
    required this.domain,
    this.fileName,
    required this.epochs,
    required this.layers,
    required this.diagnosticProfile,
  });
}

class DiagnosticStateProvider extends ChangeNotifier {
  PatientDiagnosticContext? _currentContext;
  InferenceResult? _latestResult;

  PatientDiagnosticContext? get currentContext => _currentContext;
  InferenceResult? get latestResult => _latestResult;

  void setContext(PatientDiagnosticContext context) {
    _currentContext = context;
    _latestResult = null; // Clear old results when starting new context
    notifyListeners();
  }

  void setResult(InferenceResult result) {
    _latestResult = result;
    notifyListeners();
  }

  void clearSession() {
    _currentContext = null;
    _latestResult = null;
    notifyListeners();
  }
}
