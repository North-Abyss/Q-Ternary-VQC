import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cross_file/cross_file.dart';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import '../api_service.dart';
import '../widgets/app_notification.dart';

class InferencePage extends StatefulWidget {
  const InferencePage({super.key});

  @override
  State<InferencePage> createState() => _InferencePageState();
}

class _InferencePageState extends State<InferencePage> {
  final ApiService _apiService = ApiService();
  bool _loadingSingle = false;
  bool _loadingBatch = false;
  Map<String, dynamic>? _result;
  Map<String, dynamic>? _modelInfo;
  List<dynamic> _history = [];
  String _baseUrl = '';
  
  List<String> _featureNames = [];
  List<TextEditingController> _controllers = List.generate(12, (index) => TextEditingController(text: '0.0'));

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _baseUrl = await _apiService.getBaseUrl();
    await Future.wait([
      _loadFeatureNames(),
      _loadModelInfo(),
      _loadHistory(),
    ]);
  }

  Future<void> _loadModelInfo() async {
    try {
      final info = await _apiService.getModelInfo();
      if (mounted) {
        setState(() {
          _modelInfo = info;
        });
      }
    } catch (e) {
      debugPrint('Could not load model info: $e');
    }
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _apiService.getHistory();
      if (mounted) {
        setState(() {
          _history = history.reversed.toList(); // newest first
        });
      }
    } catch (e) {
      debugPrint('Could not load history: $e');
    }
  }

  Future<void> _changeActiveModel(String timestamp) async {
    try {
      AppNotification.show(context, 'Switching Model', 'Loading model context...');
      await _apiService.setActiveModel(timestamp);
      await _loadModelInfo();
      if (mounted) {
        AppNotification.show(context, 'Success', 'Active model switched successfully.');
      }
    } catch (e) {
      if (mounted) {
        AppNotification.show(context, 'Error', 'Failed to switch model: $e', isError: true);
      }
    }
  }

  Future<void> _loadFeatureNames() async {
    try {
      final names = await _apiService.getFeatureNames();
      if (mounted) {
        setState(() {
          _featureNames = names;
          _controllers = List.generate(names.length, (index) => TextEditingController(text: '0.0'));
        });
      }
    } catch (e) {
      debugPrint('Could not load feature names: $e');
    }
  }

  Future<void> _runInference() async {
    setState(() {
      _loadingSingle = true;
      _result = null;
    });

    try {
      final features = _controllers.map((c) => double.tryParse(c.text) ?? 0.0).toList();
      final res = await _apiService.predictSingle(features);
      setState(() {
        _result = res['results'][0];
      });
    } catch (e) {
      if (mounted) {
        AppNotification.show(context, 'Inference Error', e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingSingle = false;
        });
      }
    }
  }

  Future<void> _runBatch() async {
    List<PlatformFile> result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result.isEmpty) return;

    setState(() {
      _loadingBatch = true;
    });

    try {
      final fileBytes = await result.first.readAsBytes();
      final xfile = XFile.fromData(fileBytes, name: result.first.name);
      
      final csvBytes = await _apiService.predictBatch(xfile);
      
      // Download the resulting CSV bytes
      final blob = html.Blob([csvBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'batch_predictions.csv')
        ..click();
      html.Url.revokeObjectUrl(url);
      
      if (mounted) {
        AppNotification.show(context, 'Success', 'Batch predictions downloaded!');
      }
    } catch (e) {
      if (mounted) {
        AppNotification.show(context, 'Batch Error', e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingBatch = false;
        });
      }
    }
  }

  Widget _buildSingleTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Manual Feature Input', style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(
                onPressed: () async {
                  final url = Uri.parse('$_baseUrl/download_sample?dataset=breast_cancer');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
                icon: const Icon(Icons.download),
                label: const Text('Sample Data'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: List.generate(_controllers.length, (index) {
              final label = _featureNames.isNotEmpty ? _featureNames[index] : 'Feature ${index + 1}';
              return SizedBox(
                width: 140,
                child: TextField(
                  controller: _controllers[index],
                  decoration: InputDecoration(
                    labelText: label,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _loadingSingle ? null : _runInference,
            icon: _loadingSingle ? const SizedBox(width:16, height:16, child: CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.bolt),
            label: const Text('Predict Single'),
            style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12)
              ),
              child: Column(
                children: [
                  Text('Prediction Result', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Icon(
                    _result!['quantum_prediction'] == 1 ? Icons.warning : Icons.check_circle,
                    size: 64,
                    color: _result!['quantum_prediction'] == 1 ? Colors.red : Colors.green,
                  ),
                  Text(
                    _result!['quantum_prediction'] == 1 ? 'MALIGNANT' : 'BENIGN',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: _result!['quantum_prediction'] == 1 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Confidence: ${(_result!['quantum_probability'] * 100).toStringAsFixed(2)}%'),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildBatchTab() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.upload_file, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Upload CSV for Batch Prediction', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('The backend will process all rows and return a downloadable CSV with predictions.', textAlign: TextAlign.center),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _loadingBatch ? null : _runBatch,
            icon: _loadingBatch ? const SizedBox(width:16, height:16, child: CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.upload),
            label: const Text('Select CSV and Predict'),
            style: FilledButton.styleFrom(minimumSize: const Size(250, 50)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('Quantum Inference')),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Inputs (Single / Batch)
              Expanded(
                flex: 1,
                child: Card(
                  child: Column(
                    children: [
                      const TabBar(
                        tabs: [
                          Tab(icon: Icon(Icons.person), text: 'Single Patient'),
                          Tab(icon: Icon(Icons.group), text: 'Batch Upload'),
                        ],
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: TabBarView(
                            children: [
                              _buildSingleTab(),
                              _buildBatchTab(),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Right Column: Model Info & Explainability
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    // Model Info Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.model_training, color: Colors.blueAccent),
                                const SizedBox(width: 8),
                                Text('Active Model Context', style: Theme.of(context).textTheme.titleLarge),
                                const Spacer(),
                                if (_history.isNotEmpty)
                                  DropdownButton<String>(
                                    value: _modelInfo?['timestamp'],
                                    hint: const Text('Select Model'),
                                    items: _history.map((run) {
                                      return DropdownMenuItem<String>(
                                        value: run['timestamp'],
                                        child: Text('${run['dataset']} - ${run['timestamp'].toString().split('T')[0]}'),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) _changeActiveModel(val);
                                    },
                                  ),
                              ],
                            ),
                            const Divider(),
                            if (_modelInfo != null && _modelInfo!['status'] == 'success') ...[
                              ListTile(
                                leading: const Icon(Icons.dataset),
                                title: const Text('Dataset'),
                                trailing: Text('${_modelInfo!['dataset']}'),
                              ),
                              ListTile(
                                leading: const Icon(Icons.settings),
                                title: const Text('Hyperparameters'),
                                trailing: Text('Epochs: ${_modelInfo!['epochs']} | Layers: ${_modelInfo!['layers']}'),
                              ),
                              ListTile(
                                leading: const Icon(Icons.score),
                                title: const Text('Validation F1 Score'),
                                trailing: Text('${_modelInfo!['f1_score']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                              ),
                            ] else ...[
                              const Center(child: Text('No model loaded. Please run training first.')),
                            ]
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Explainability Card
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.psychology, color: Colors.purpleAccent),
                                  const SizedBox(width: 8),
                                  Text('SHAP Global Explanations', style: Theme.of(context).textTheme.titleLarge),
                                ],
                              ),
                              const Divider(),
                              Expanded(
                                child: _baseUrl.isEmpty 
                                  ? const Center(child: CircularProgressIndicator()) 
                                  : InteractiveViewer(
                                      child: Image.network(
                                        '$_baseUrl/shap_images?timestamp=${_modelInfo?['timestamp'] ?? ''}',
                                        key: ValueKey(_modelInfo?['timestamp'] ?? 'shap'),
                                        errorBuilder: (context, error, stackTrace) => Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text('SHAP summary plot not available.', textAlign: TextAlign.center),
                                              const SizedBox(height: 16),
                                              if (_modelInfo != null && _modelInfo!['status'] == 'success')
                                                FilledButton.icon(
                                                  icon: const Icon(Icons.bar_chart),
                                                  label: const Text('Generate Explanations'),
                                                  onPressed: () async {
                                                    try {
                                                      AppNotification.show(context, 'Generating', 'Please wait...');
                                                      await _apiService.generateGraphs(_modelInfo!['timestamp']);
                                                      setState(() {}); // reload image
                                                      if (context.mounted) {
                                                        AppNotification.show(context, 'Success', 'Graphs generated!');
                                                      }
                                                    } catch (e) {
                                                      if (context.mounted) {
                                                        AppNotification.show(context, 'Error', e.toString(), isError: true);
                                                      }
                                                    }
                                                  },
                                                )
                                              else
                                                const Text('Train the model to generate one.', textAlign: TextAlign.center),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
