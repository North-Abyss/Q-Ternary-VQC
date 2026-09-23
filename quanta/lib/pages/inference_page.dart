import 'package:flutter/material.dart';
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
  
  // Dummy 12 features for breast cancer
  final List<TextEditingController> _controllers = List.generate(12, (index) => TextEditingController(text: '0.0'));

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
                      Text('Clinical Features', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: List.generate(12, (index) {
                          return SizedBox(
                            width: 100,
                            child: TextField(
                              controller: _controllers[index],
                              decoration: InputDecoration(
                                labelText: 'Feature ${index + 1}',
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
