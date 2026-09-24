import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cross_file/cross_file.dart';
import '../api_service.dart';
import '../providers/diagnostic_state_provider.dart';

class PatientIntakeForm extends StatefulWidget {
  const PatientIntakeForm({super.key});

  @override
  State<PatientIntakeForm> createState() => _PatientIntakeFormState();
}

class _PatientIntakeFormState extends State<PatientIntakeForm> {
  final ApiService _api = ApiService();
  
  String _dataset = 'breast_cancer';
  String _diagnosticProfile = 'standard';
  double _epochs = 50;
  double _layers = 3;
  bool _developerMode = false;

  bool _isUploading = false;
  bool _dataUploaded = false;
  String? _fileName;
  Map<String, dynamic>? _preview;

  void _pickAndUpload() {
    final web.HTMLInputElement uploadInput = web.document.createElement('input') as web.HTMLInputElement;
    uploadInput.type = 'file';
    uploadInput.accept = '.csv,.dcm,.vcf,.json';
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
                _preview = res["preview"];
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

  void _startDiagnostic() {
    if (!_dataUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload a dataset first.')));
      return;
    }

    DiseaseDomain domain = DiseaseDomain.unknown;
    if (_dataset == 'breast_cancer') domain = DiseaseDomain.oncology;
    if (_dataset == 'heart_disease') domain = DiseaseDomain.cardiovascular;
    if (_dataset == 'parkinsons') domain = DiseaseDomain.neurological;

    final contextData = PatientDiagnosticContext(
      patientId: 'PAT-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      domain: domain,
      fileName: _fileName,
      epochs: _epochs,
      layers: _layers,
      diagnosticProfile: _diagnosticProfile,
    );

    Provider.of<DiagnosticStateProvider>(context, listen: false).setContext(contextData);
    
    // Navigate to Pipeline
    Navigator.of(context).pushNamed('/pipeline');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _dataUploaded ? Colors.green.withOpacity(0.2) : Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _dataUploaded ? Icons.check : Icons.upload_file, 
                        color: _dataUploaded ? Colors.green : Theme.of(context).colorScheme.primary
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text('Patient Intake', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    const Text('Dev Mode', style: TextStyle(fontSize: 12)),
                    Switch(value: _developerMode, onChanged: (v) => setState(() => _developerMode = v)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('1. Data Upload', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
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
                                const CircularProgressIndicator()
                              else ...[
                                Icon(Icons.folder_shared_outlined, size: 48, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(height: 16),
                                Text(
                                  _fileName ?? 'Select Patient Dataset (.csv, .dcm, .vcf, .json)\nor drag-and-drop file here', 
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (_preview != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dataset Preview', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text('Rows: ${_preview!["rows"]} | Features: ${_preview!["features"]}', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        )
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('2. Diagnostic Configuration', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      const Text('Disease Domain:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      DropdownButton<String>(
                        value: _dataset,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'breast_cancer', child: Text("Cancer (Wisconsin Breast Cancer)")),
                          DropdownMenuItem(value: 'heart_disease', child: Text("Cardiovascular (EHR Heart Disease)")),
                          DropdownMenuItem(value: 'parkinsons', child: Text("Neurological (Parkinson's Genomics)")),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _dataset = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      if (!_developerMode) ...[
                        const Text('Depth Profile:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'quick', label: Text('Quick')),
                            ButtonSegment(value: 'standard', label: Text('Standard')),
                            ButtonSegment(value: 'deep', label: Text('Deep')),
                          ],
                          selected: {_diagnosticProfile},
                          onSelectionChanged: (Set<String> newSelection) {
                            setState(() {
                              _diagnosticProfile = newSelection.first;
                              if (_diagnosticProfile == 'quick') { _epochs = 20; _layers = 1; }
                              else if (_diagnosticProfile == 'standard') { _epochs = 50; _layers = 3; }
                              else if (_diagnosticProfile == 'deep') { _epochs = 120; _layers = 6; }
                            });
                          },
                        ),
                      ] else ...[
                        const Text('Epochs:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Slider(
                          value: _epochs, min: 10, max: 200, divisions: 19,
                          onChanged: (val) => setState(() => _epochs = val),
                        ),
                        const Text('VQC Layers:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Slider(
                          value: _layers, min: 1, max: 10, divisions: 9,
                          onChanged: (val) => setState(() => _layers = val),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _dataUploaded ? _startDiagnostic : null,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Run Diagnostic Pipeline'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
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
}
