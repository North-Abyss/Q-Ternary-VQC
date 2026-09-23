import 'dart:async';
import 'dart:js_interop';
import 'dart:convert';
import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../api_service.dart';


class PipelinePage extends StatefulWidget {
  const PipelinePage({super.key});

  @override
  State<PipelinePage> createState() => _PipelinePageState();
}

class _PipelinePageState extends State<PipelinePage> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  double _epochs = 50;
  double _layers = 3;
  
  bool _isTraining = false;
  bool _isUploading = false;
  bool _dataUploaded = false;
  String? _fileName;
  
  List<String> _logs = [];
  Timer? _timer;
  
  bool _developerMode = false;
  
  DateTime? _trainStartTime;
  int _elapsedSeconds = 0;
  int _currentEpoch = 0;
  Timer? _stopwatchTimer;
  
  late AnimationController _wiggleController;

  @override
  void initState() {
    super.initState();
    _checkStatus();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkStatus();
    });
    
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _stopwatchTimer?.cancel();
    _wiggleController.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    try {
      final res = await _api.getTrainStatus();
      if (mounted) {
        setState(() {
          _isTraining = res['is_running'] ?? false;
          final List<dynamic> logs = res['logs'] ?? [];
          _logs = logs.map((e) => e.toString()).toList();
          
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
          }
        });
      }
    } catch (e) {
      // API might be down or not responding, ignore gracefully
    }
  }

  Future<void> _startTraining() async {
    try {
      setState(() {
        _isTraining = true;
        _logs = ["Triggering training backend..."];
        _trainStartTime = DateTime.now();
        _elapsedSeconds = 0;
        _currentEpoch = 0;
        _stopwatchTimer?.cancel();
        _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted && _isTraining) {
            setState(() {
              _elapsedSeconds = DateTime.now().difference(_trainStartTime!).inSeconds;
            });
          }
        });
      });
      await _api.triggerTraining({
        "epochs": _epochs.toInt(),
        "layers": _layers.toInt(),
        "dataset": "breast_cancer"
      });
      _checkStatus();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTraining = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
  
  void _pickAndUpload() {
    final web.HTMLInputElement uploadInput = web.document.createElement('input') as web.HTMLInputElement;
    uploadInput.type = 'file';
    uploadInput.accept = '.csv';
    uploadInput.click();

    uploadInput.onChange.listen((web.Event e) {
      final web.FileList? files = uploadInput.files;
      if (files != null && files.length > 0) {
        final web.File file = files.item(0)!;
        
        setState(() {
          _fileName = file.name;
          _isUploading = true;
        });

        final web.FileReader reader = web.FileReader();
        reader.readAsArrayBuffer(file);
        reader.onLoadEnd.listen((web.ProgressEvent e) async {
          try {
            final JSArrayBuffer buffer = reader.result as JSArrayBuffer;
            final bytes = buffer.toDart.asUint8List();
            final xfile = XFile.fromData(bytes, name: file.name);
            
            final res = await _api.uploadDataset(xfile);
            
            if (mounted) {
              setState(() {
                _dataUploaded = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Success: ${res["message"]}'), backgroundColor: Colors.green),
              );
            }
          } catch (error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
              );
            }
          } finally {
            if (mounted) {
              setState(() {
                _isUploading = false;
              });
            }
          }
        });
      }
    });
  }

  void _downloadLogs() {
    final String logText = _logs.join('\n');
    final bytes = utf8.encode(logText);
    final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'text/plain'));
    final url = web.URL.createObjectURL(blob);
    
    final web.HTMLAnchorElement anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.download = 'training_logs.txt';
    anchor.click();
    web.URL.revokeObjectURL(url);
  }

  Widget _buildWigglingLoader() {
    final String minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final String seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    final double maxEpochs = _epochs;
    final double percent = maxEpochs > 0 ? (_currentEpoch / maxEpochs) : 0;
    
    return AnimatedBuilder(
      animation: _wiggleController,
      builder: (context, child) {
        return Transform.rotate(
          angle: (_wiggleController.value - 0.5) * 0.1, // subtle wiggle
          child: child,
        );
      },
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 5,
            )
          ]
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: CircularProgressIndicator(
                value: percent > 0 ? percent : null,
                strokeWidth: 8,
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$minutes:$seconds',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
                Text(
                  '${(percent * 100).toInt()}%',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
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
      appBar: AppBar(title: const Text('Q-Ternary Pipeline')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Data Upload and Hyperparameters
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  // Step 1: Data Setup
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _dataUploaded ? Colors.green.withValues(alpha: 0.2) : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _dataUploaded ? Icons.check : Icons.upload_file, 
                                  color: _dataUploaded ? Colors.green : Theme.of(context).colorScheme.primary
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Text('1. Data Setup', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          InkWell(
                            onTap: _isUploading ? null : _pickAndUpload,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24.0),
                              decoration: BoxDecoration(
                                border: Border.all(color: Theme.of(context).dividerColor),
                                borderRadius: BorderRadius.circular(12),
                                color: Theme.of(context).scaffoldBackgroundColor,
                              ),
                              child: Column(
                                children: [
                                  if (_isUploading)
                                    _buildWigglingLoader()
                                  else
                                    Icon(Icons.cloud_upload_outlined, size: 48, color: Theme.of(context).colorScheme.primary),
                                  const SizedBox(height: 16),
                                  Text(_fileName ?? 'Click to upload dataset (.csv)'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton.icon(
                              onPressed: () async {
                                final baseUrl = await _api.getBaseUrl();
                                final uri = Uri.parse('$baseUrl/download_sample?dataset=breast_cancer');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                              icon: const Icon(Icons.download, size: 16),
                              label: const Text('Download Sample Breast Cancer CSV'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Step 2: Training Config
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.settings, color: Theme.of(context).colorScheme.secondary),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Text('2. Hyperparameters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text('Epochs: ${_epochs.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Slider(
                            value: _epochs,
                            min: 10,
                            max: 200,
                            divisions: 19,
                            onChanged: _isTraining ? null : (val) => setState(() => _epochs = val),
                          ),
                          const SizedBox(height: 16),
                          Text('VQC Layers: ${_layers.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Slider(
                            value: _layers,
                            min: 1,
                            max: 10,
                            divisions: 9,
                            onChanged: _isTraining ? null : (val) => setState(() => _layers = val),
                          ),
                          const SizedBox(height: 32),
                          FilledButton.icon(
                            onPressed: (_isTraining || !_dataUploaded) ? null : _startTraining,
                            icon: _isTraining 
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                                : const Icon(Icons.play_arrow),
                            label: Text(_isTraining ? 'Training in Progress...' : 'Start Training Pipeline'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          if (!_dataUploaded)
                            const Padding(
                              padding: EdgeInsets.only(top: 12.0),
                              child: Center(child: Text('Please upload a dataset first.', style: TextStyle(color: Colors.redAccent, fontSize: 12))),
                            )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            
            // Right Column: Output Abstraction
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
                          const Text('Pipeline Status', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              const Text('Developer Mode', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 8),
                              Switch(
                                value: _developerMode,
                                onChanged: (val) => setState(() => _developerMode = val),
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: _developerMode 
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: _logs.isEmpty 
                                ? const Center(child: Text('No active pipeline jobs.', style: TextStyle(color: Colors.white54)))
                                : ListView.builder(
                                    itemCount: _logs.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 4.0),
                                        child: SelectableText(
                                          _logs[index], 
                                          style: const TextStyle(fontFamily: 'monospace', color: Colors.greenAccent, fontSize: 13),
                                        ),
                                      );
                                    },
                                  ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isTraining) ...[
                                    _buildWigglingLoader(),
                                    const SizedBox(height: 32),
                                    Text('Running Hybrid Quantum Compilation...', style: Theme.of(context).textTheme.titleLarge),
                                    const SizedBox(height: 16),
                                    const Text('Compiling data to 3² representation and executing parameterized circuits.', style: TextStyle(color: Colors.grey)),
                                  ] else if (_logs.isNotEmpty && _logs.last.contains('Complete')) ...[
                                    const Icon(Icons.check_circle, size: 100, color: Colors.green),
                                    const SizedBox(height: 32),
                                    Text('Pipeline Execution Complete', style: Theme.of(context).textTheme.titleLarge),
                                    const SizedBox(height: 16),
                                    const Text('Models successfully compiled and saved.', style: TextStyle(color: Colors.grey)),
                                    const SizedBox(height: 24),
                                    FilledButton.icon(
                                      onPressed: _downloadLogs,
                                      icon: const Icon(Icons.download),
                                      label: const Text('Download Training Report'),
                                    )
                                  ] else ...[
                                    Icon(Icons.bolt, size: 100, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
                                    const SizedBox(height: 32),
                                    Text('Pipeline Idle', style: Theme.of(context).textTheme.titleLarge),
                                    const SizedBox(height: 16),
                                    const Text('Upload a dataset and configure hyperparameters to begin.', style: TextStyle(color: Colors.grey)),
                                  ]
                                ],
                              ),
                            ),
                      ),
                      if (_logs.isNotEmpty && !_isTraining) ...[
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.tonalIcon(
                                onPressed: _downloadLogs,
                                icon: const Icon(Icons.download),
                                label: const Text('Download Logs'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: FilledButton.tonalIcon(
                                onPressed: () async {
                                  final text = _logs.join('\n');
                                  await Clipboard.setData(ClipboardData(text: text));
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logs copied to clipboard.')));
                                },
                                icon: const Icon(Icons.copy),
                                label: const Text('Copy Logs'),
                              ),
                            ),
                          ],
                        )
                      ]
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
