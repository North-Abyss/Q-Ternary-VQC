import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api_service.dart';

class InferencePage extends StatefulWidget {
  const InferencePage({super.key});

  @override
  State<InferencePage> createState() => _InferencePageState();
}

class _InferencePageState extends State<InferencePage> {
  final ApiService _apiService = ApiService();
  bool _loading = false;
  Map<String, dynamic>? _result;
  
  List<String> _featureNames = [];
  List<TextEditingController> _controllers = List.generate(12, (index) => TextEditingController(text: '0.0'));

  @override
  void initState() {
    super.initState();
    _loadFeatureNames();
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
      _loading = true;
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quantum Inference')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Clinical Features', style: Theme.of(context).textTheme.titleLarge),
                          TextButton.icon(
                            onPressed: () async {
                              final baseUrl = await _apiService.getBaseUrl();
                              final url = Uri.parse('$baseUrl/download_sample?dataset=breast_cancer');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              }
                            },
                            icon: const Icon(Icons.download),
                            label: const Text('Download Sample Data'),
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
                        onPressed: _loading ? null : _runInference,
                        icon: _loading ? const SizedBox(width:16, height:16, child: CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.bolt),
                        label: const Text('Predict'),
                        style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 1,
              child: _result == null 
                  ? const Card(child: Center(child: Text('Run prediction to see results.')))
                  : Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Prediction Result', style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 32),
                            Icon(
                              _result!['quantum_prediction'] == 1 ? Icons.warning : Icons.check_circle,
                              size: 80,
                              color: _result!['quantum_prediction'] == 1 ? Colors.red : Colors.green,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _result!['quantum_prediction'] == 1 ? 'MALIGNANT' : 'BENIGN',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: _result!['quantum_prediction'] == 1 ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                            const SizedBox(height: 24),
                            LinearProgressIndicator(
                              value: _result!['quantum_probability'],
                              minHeight: 12,
                              color: _result!['quantum_prediction'] == 1 ? Colors.red : Colors.green,
                            ),
                            const SizedBox(height: 8),
                            Text('Confidence: ${(_result!['quantum_probability'] * 100).toStringAsFixed(2)}%'),
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
