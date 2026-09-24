import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cross_file/cross_file.dart';
import '../api_service.dart';
import '../widgets/app_notification.dart';
import '../providers/theme_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ApiService _api = ApiService();
  List<dynamic> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _api.getHistory();
      if (mounted) {
        setState(() {
          _history = history.reversed.toList(); // Newest first
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showHistoryDetails(BuildContext context, Map<String, dynamic> run) {
    final String dataset = run['dataset'] ?? 'Unknown';
    final int epochs = run['epochs'] ?? 0;
    final int layers = run['layers'] ?? 0;
    final String f1Score = run['f1_score'] ?? 'N/A';
    final bool isSuccess = run['success'] == true;
    final List<dynamic> rawLogs = run['logs'] ?? [];
    final String logsText = rawLogs.join('\n');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Run Details - $dataset'),
        content: SizedBox(
          width: 800,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Status: ${isSuccess ? 'Success' : 'Failed'}', style: TextStyle(color: isSuccess ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                  Text('F1 Score: $f1Score', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Parameters: Epochs: $epochs, Layers: $layers'),
              const Divider(),
              const Text('Logs:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      logsText.isEmpty ? 'No logs available.' : logsText,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              try {
                AppNotification.show(ctx, 'Generating Graphs', 'This may take a moment...');
                final timestamp = run['timestamp'] ?? '';
                final res = await _api.generateGraphs(timestamp);
                if (ctx.mounted) {
                  AppNotification.show(ctx, 'Success', res['message'] ?? 'Graphs generated.');
                }
              } catch (e) {
                if (ctx.mounted) {
                  AppNotification.show(ctx, 'Error', e.toString(), isError: true);
                }
              }
            },
            icon: const Icon(Icons.bar_chart),
            label: const Text('Generate Graphs'),
          ),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: logsText));
              if (ctx.mounted) {
                AppNotification.show(context, 'Copied', 'Logs copied to clipboard.');
              }
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy Logs'),
          ),
          TextButton.icon(
            onPressed: () async {
              final bytes = utf8.encode(logsText);
              final xfile = XFile.fromData(Uint8List.fromList(bytes), name: 'training_logs_$dataset.txt', mimeType: 'text/plain');
              await xfile.saveTo('training_logs_$dataset.txt');
            },
            icon: const Icon(Icons.download),
            label: const Text('Download Logs'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _cleanupSystem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clean-up System'),
        content: const Text('This will delete all saved models, weights, and run history. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _api.cleanupModels();
        if (mounted) {
          AppNotification.show(context, 'Cleanup', 'System cleaned up successfully.');
          _loadHistory();
        }
      } catch (e) {
        if (mounted) {
          AppNotification.show(context, 'Cleanup Error', e.toString(), isError: true);
        }
      }
    }
  }

  Future<void> _downloadModel(String filename) async {
    final baseUrl = await _api.getBaseUrl();
    final url = _api.getDownloadUrl(baseUrl, filename);
    if (!await launchUrl(Uri.parse(url))) {
      if (mounted) {
        AppNotification.show(context, 'Download Error', 'Could not download $filename', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    // Calculate stats
    final totalRuns = _history.length;
    final successfulRuns = _history.where((run) => run['success'] == true).length;
    final successRate = totalRuns > 0 ? '${(successfulRuns / totalRuns * 100).toStringAsFixed(1)}%' : 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadHistory();
            },
            tooltip: 'Refresh Data',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Welcome to Q-Ternary VQC', style: Theme.of(context).textTheme.headlineMedium),
                FilledButton.tonalIcon(
                  onPressed: _cleanupSystem,
                  icon: const Icon(Icons.delete_sweep),
                  label: const Text('Clean-up System'),
                  style: FilledButton.styleFrom(foregroundColor: Colors.red),
                )
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildStatCard(context, 'Total Pipeline Runs', '$totalRuns', Icons.history),
                const SizedBox(width: 16),
                _buildStatCard(context, 'Success Rate', successRate, Icons.analytics),
                const SizedBox(width: 16),
                _buildStatCard(context, 'Active Theme', themeProvider.activeThemeName, Icons.palette),
              ],
            ),
            const SizedBox(height: 32),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Run History
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Run History', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      Card(
                        child: _isLoading 
                          ? const Padding(
                              padding: EdgeInsets.all(48.0),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : _history.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(48.0),
                                child: Center(child: Text('No pipeline runs recorded yet.', style: TextStyle(color: Colors.grey))),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _history.length,
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final run = _history[index];
                                  final isSuccess = run['success'] == true;
                                  
                                  // Parse timestamp safely
                                  String timeStr = 'Unknown';
                                  if (run['timestamp'] != null) {
                                    try {
                                      final dt = DateTime.parse(run['timestamp']);
                                      timeStr = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                                    } catch (e) {
                                      timeStr = run['timestamp'].toString();
                                    }
                                  }

                                  return ListTile(
                                    leading: Icon(
                                      isSuccess ? Icons.check_circle : Icons.error,
                                      color: isSuccess ? Colors.green : Colors.red,
                                    ),
                                    title: Text('Dataset: ${run['dataset']}'),
                                    subtitle: Text('$timeStr  |  Epochs: ${run['epochs']}  |  Layers: ${run['layers']}'),
                                    onTap: () => _showHistoryDetails(context, run),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                
                // Right Column: Model Artifacts & Preferences
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Model Artifacts', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.download),
                              title: const Text('Qutrit VQC Weights'),
                              subtitle: const Text('.pt file'),
                              onTap: () => _downloadModel('qutrit_vqc_weights.pt'),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.download),
                              title: const Text('Feature Selector'),
                              subtitle: const Text('.pkl file'),
                              onTap: () => _downloadModel('feature_selector.pkl'),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.download),
                              title: const Text('Preprocessor'),
                              subtitle: const Text('.pkl file'),
                              onTap: () => _downloadModel('preprocessor.pkl'),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      Text('Active Preferences', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPrefRow('Theme Mode', themeProvider.themeMode.name.toUpperCase()),
                              const Divider(),
                              _buildPrefRow('Menu Position', themeProvider.menuPosition.name.toUpperCase()),
                              const Divider(),
                              _buildPrefRow('Centered Icons', themeProvider.isMenuCentered ? 'ON' : 'OFF'),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrefRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
                ],
              ),
              const SizedBox(height: 16),
              Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
