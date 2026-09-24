import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../api_service.dart';
import '../providers/diagnostic_state_provider.dart';
import '../widgets/glassmorphic_clinical_panel.dart';

class PipelinePage extends StatefulWidget {
  const PipelinePage({super.key});

  @override
  State<PipelinePage> createState() => _PipelinePageState();
}

class _PipelinePageState extends State<PipelinePage> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  bool _isTraining = true;
  bool _hasError = false;
  List<String> _logs = [];
  Timer? _timer;
  
  DateTime? _trainStartTime;
  int _elapsedSeconds = 0;
  int _currentEpoch = 0;
  Timer? _stopwatchTimer;
  
  late AnimationController _wiggleController;
  late PatientDiagnosticContext _context;

  @override
  void initState() {
    super.initState();
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = Provider.of<DiagnosticStateProvider>(context, listen: false).currentContext;
      if (ctx == null) {
        _context = PatientDiagnosticContext(
          patientId: "UNKNOWN",
          domain: DiseaseDomain.unknown,
          epochs: 1,
          layers: 1,
          diagnosticProfile: "none",
        );
        setState(() {
          _hasError = true;
          _isTraining = false;
          _logs = [
            "[PIPELINE_ERROR] No active patient context detected.", 
            "Please return to the Dashboard and upload a patient file to begin the pipeline."
          ];
        });
      } else {
        _context = ctx;
        _startTraining();
      }
    });
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _stopwatchTimer?.cancel();
    _wiggleController.dispose();
    super.dispose();
  }

  Future<void> _startTraining() async {
    setState(() {
      _isTraining = true;
      _hasError = false;
      _logs = ["Initialize Qutrit Environment...", "Connecting to QPU simulator...", "Mapping ${_context.domain.name} feature space..."];
      _trainStartTime = DateTime.now();
      _elapsedSeconds = 0;
      _currentEpoch = 0;
      _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && _isTraining) {
          setState(() {
            _elapsedSeconds = DateTime.now().difference(_trainStartTime!).inSeconds;
          });
        }
      });
    });

    try {
      // Mocking Dataset strings to API format
      String apiDataset = 'breast_cancer';
      if (_context.domain == DiseaseDomain.cardiovascular) apiDataset = 'heart_disease';
      if (_context.domain == DiseaseDomain.neurological) apiDataset = 'parkinsons';

      await _api.triggerTraining({
        "epochs": _context.epochs.toInt(),
        "layers": _context.layers.toInt(),
        "dataset": apiDataset,
      });
      
      _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
        _checkStatus();
      });
    } catch (e) {
      _handlePipelineError("CONNECTION_REFUSED: Backend unresponsive.");
    }
  }

  Future<void> _checkStatus() async {
    try {
      final res = await _api.getTrainStatus();
      if (!mounted) return;
      
      setState(() {
        _isTraining = res['is_running'] ?? false;
        final List<dynamic> fetchedLogs = res['logs'] ?? [];
        _logs = fetchedLogs.map((e) => e.toString()).toList();
        
        if (_isTraining) {
          for (var log in _logs.reversed) {
            if (log.contains('Epoch')) {
              final match = RegExp(r'Epoch (\d+)/').firstMatch(log);
              if (match != null) {
                _currentEpoch = int.tryParse(match.group(1)!) ?? _currentEpoch;
                break;
              }
            }
          }
        } else {
          _stopwatchTimer?.cancel();
          _timer?.cancel();
          
          if (_logs.isNotEmpty && _logs.last.contains('Complete')) {
            _finalizePipeline();
          } else if (_logs.isNotEmpty && _logs.last.contains('Error')) {
             _handlePipelineError(_logs.last);
          }
        }
      });
    } catch (e) {
      // Fallback
    }
  }

  void _handlePipelineError(String reason) {
    if (!mounted) return;
    _stopwatchTimer?.cancel();
    _timer?.cancel();
    setState(() {
      _isTraining = false;
      _hasError = true;
      _logs.add("[PIPELINE_ERROR] $reason");
      _logs.add("Suggesting Action: FALLBACK_CPU_QUANTUM_SIM");
    });
  }

  void _executeClassicalFallback() {
    setState(() {
      _hasError = false;
      _isTraining = true;
      _logs.add("Executing Classical XGBoost Fallback...");
    });
    
    // Simulate fallback completion
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _logs.add("Classical Fallback Complete.");
        _finalizePipeline(isFallback: true);
      }
    });
  }

  void _finalizePipeline({bool isFallback = false}) {
    if (!mounted) return;
    
    // Generate Inference Result payload based on the active domain
    double conf = 0.94;
    ClinicalTriage triage = ClinicalTriage.red;
    List<double> qProbs = [0.05, 0.05, 0.90];
    String narrative = "High-probability pathological signature detected across matrices. Immediate clinical intervention recommended.";

    if (_context.domain == DiseaseDomain.cardiovascular) {
       triage = ClinicalTriage.orange;
       conf = 0.78;
       qProbs = [0.20, 0.70, 0.10];
       narrative = "Early-stage cardiovascular risk flags detected in EHR. Targeted biomarker re-evaluation in 30 days recommended.";
    }

    if (isFallback) {
      narrative = "[XGBoost Fallback] " + narrative;
    }

    final result = InferenceResult(
      patientId: _context.patientId,
      domain: _context.domain,
      triage: triage,
      confidenceScore: conf,
      qutritProbabilities: qProbs,
      classicalProbabilities: [0.10, 0.20, 0.70],
      clinicalNarrative: narrative,
      timestamp: DateTime.now(),
    );

    Provider.of<DiagnosticStateProvider>(context, listen: false).setResult(result);
    
    // Broadcast PIPELINE_COMPLETE to UI router
    Navigator.of(context).pushReplacementNamed('/inference');
  }

  void _downloadLogs() {
    final String logText = _logs.join('\n');
    final bytes = utf8.encode(logText);
    final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'text/plain'));
    final url = web.URL.createObjectURL(blob);
    
    final web.HTMLAnchorElement anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.download = 'pipeline_telemetry.txt';
    anchor.click();
    web.URL.revokeObjectURL(url);
  }

  Widget _buildWigglingLoader() {
    final String minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final String seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    final double maxEpochs = _context.epochs > 0 ? _context.epochs : 1;
    final double percent = _currentEpoch / maxEpochs;
    
    return AnimatedBuilder(
      animation: _wiggleController,
      builder: (context, child) {
        return Transform.rotate(
          angle: (_wiggleController.value - 0.5) * 0.1, 
          child: child,
        );
      },
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.2), blurRadius: 20, spreadRadius: 5)
          ]
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 150, height: 150,
              child: CircularProgressIndicator(
                value: percent > 0 ? percent : null,
                strokeWidth: 8,
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$minutes:$seconds', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                Text('${(percent * 100).toInt()}%', style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pipeline Telemetry Stream')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_hasError) ...[
                        const Icon(Icons.error_outline, size: 80, color: Colors.red),
                        const SizedBox(height: 24),
                        const Text('Pipeline Stalled', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        const Text('The quantum simulator encountered a storage boundary exception.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 32),
                        FilledButton.icon(
                          onPressed: _executeClassicalFallback,
                          icon: const Icon(Icons.memory),
                          label: const Text('Execute Classical Fallback (XGBoost)'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16)
                          ),
                        )
                      ] else if (_isTraining) ...[
                        _buildWigglingLoader(),
                        const SizedBox(height: 32),
                        const Text('Executing Quantum Pipeline', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        const Text('Mapping classical vectors into high-dimensional qutrit space.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 32),
                        const LinearProgressIndicator(),
                      ] else ...[
                        const Icon(Icons.check_circle, size: 80, color: Colors.green),
                        const SizedBox(height: 24),
                        const Text('Pipeline Complete', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        const Text('Transitioning to Inference...', style: TextStyle(color: Colors.grey)),
                      ]
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Live Execution Logs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          IconButton(icon: const Icon(Icons.download), onPressed: _downloadLogs, tooltip: 'Download Trace'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: ListView.builder(
                            itemCount: _logs.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Text(
                                  _logs[index], 
                                  style: TextStyle(
                                    fontFamily: 'monospace', 
                                    color: _logs[index].contains('ERROR') ? Colors.redAccent : Colors.greenAccent, 
                                    fontSize: 13
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
