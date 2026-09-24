import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'dart:convert';
import '../api_service.dart';
import '../widgets/app_notification.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final ApiService _apiService = ApiService();
  bool _loading = true;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _apiService.getHistory();
      if (mounted) {
        setState(() {
          // Reverse to show latest first
          _history = history.reversed.toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        AppNotification.show(context, 'History Error', 'Error loading history: $e', isError: true);
      }
    }
  }

  void _downloadLogs(String timestamp, List<dynamic> logs) {
    final text = logs.join('\n');
    final bytes = utf8.encode(text);
    final uint8Bytes = Uint8List.fromList(bytes);
    final blob = web.Blob([uint8Bytes.toJS].toJS);
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..download = 'training_logs_$timestamp.txt';
    web.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    web.URL.revokeObjectURL(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training History & Datasets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loading = true;
              });
              _loadHistory();
            },
          )
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: Datasets
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Stress Test Datasets', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      const Text('Use these official standard datasets to evaluate the model performance and robustness.'),
                      const SizedBox(height: 24),
                      ListTile(
                        leading: const Icon(Icons.medical_services, color: Colors.green),
                        title: const Text('Wisconsin Breast Cancer (Diagnostic)'),
                        subtitle: const Text('UCI Machine Learning Repository. Binary classification of tumor malignancy.'),
                        trailing: const Icon(Icons.open_in_new),
                        onTap: () => launchUrl(Uri.parse('https://archive.ics.uci.edu/dataset/17/breast+cancer+wisconsin+diagnostic')),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.water_drop, color: Colors.blue),
                        title: const Text('Chronic Kidney Disease (CKD)'),
                        subtitle: const Text('UCI Machine Learning Repository. Predictive features for chronic kidney disease.'),
                        trailing: const Icon(Icons.open_in_new),
                        onTap: () => launchUrl(Uri.parse('https://archive.ics.uci.edu/dataset/336/chronic+kidney+disease')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Right side: History
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 12.0),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _history.isEmpty
                      ? const Center(child: Text('No training history found.'))
                      : ListView.builder(
                          itemCount: _history.length,
                          itemBuilder: (context, index) {
                            final run = _history[index];
                            final timestamp = run['timestamp'] ?? '';
                            final dt = DateTime.tryParse(timestamp)?.toLocal() ?? DateTime.now();
                            final dateStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
                            final logs = run['logs'] as List<dynamic>? ?? [];
                            final f1Score = run['f1_score'] ?? 'N/A';
                            final isSuccess = run['success'] == true;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: ExpansionTile(
                                leading: Icon(
                                  isSuccess ? Icons.check_circle : Icons.error,
                                  color: isSuccess ? Colors.green : Colors.red,
                                ),
                                title: Text('Run on $dateStr'),
                                subtitle: Text(
                                  'Dataset: ${run['dataset']} | Epochs: ${run['epochs']} | Layers: ${run['layers']} | F1: $f1Score',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Training Logs', style: Theme.of(context).textTheme.titleMedium),
                                            Row(
                                              children: [
                                                TextButton.icon(
                                                  icon: const Icon(Icons.bar_chart, size: 16),
                                                  label: const Text('Generate Graphs'),
                                                  onPressed: () async {
                                                    try {
                                                      AppNotification.show(context, 'Generating Graphs', 'This may take a moment...');
                                                      final res = await _apiService.generateGraphs(timestamp);
                                                      if (context.mounted) {
                                                        AppNotification.show(context, 'Success', res['message'] ?? 'Graphs generated.');
                                                      }
                                                    } catch (e) {
                                                      if (context.mounted) {
                                                        AppNotification.show(context, 'Error', e.toString(), isError: true);
                                                      }
                                                    }
                                                  },
                                                ),
                                                TextButton.icon(
                                                  icon: const Icon(Icons.copy, size: 16),
                                                  label: const Text('Copy'),
                                                  onPressed: () {
                                                    Clipboard.setData(ClipboardData(text: logs.join('\n')));
                                                    AppNotification.show(context, 'Copied', 'Logs copied to clipboard');
                                                  },
                                                ),
                                                TextButton.icon(
                                                  icon: const Icon(Icons.download, size: 16),
                                                  label: const Text('Download'),
                                                  onPressed: () => _downloadLogs(timestamp, logs),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          height: 300,
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.black87,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: SingleChildScrollView(
                                            child: Text(
                                              logs.join('\n'),
                                              style: const TextStyle(fontFamily: 'monospace', color: Colors.greenAccent, fontSize: 12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
