import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/diagnostic_state_provider.dart';
import '../widgets/glassmorphic_clinical_panel.dart';

class InferencePage extends StatelessWidget {
  const InferencePage({super.key});

  @override
  Widget build(BuildContext context) {
    final stateProvider = Provider.of<DiagnosticStateProvider>(context);
    final result = stateProvider.latestResult;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quantum Inference Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting report...')),
              );
            },
            tooltip: 'Print Report',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: result == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_late, size: 80, color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                  const SizedBox(height: 24),
                  const Text('No Diagnostic Result Available', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('Please return to the Dashboard and run a patient pipeline first.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Return to Dashboard'),
                  )
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    children: [
                      GlassmorphicClinicalPanel(
                        triage: result.triage,
                        confidenceScore: result.confidenceScore,
                        qutritProbabilities: result.qutritProbabilities,
                        diseaseDomain: result.domain.name.toUpperCase(),
                        clinicalInterpretation: result.clinicalNarrative,
                        onExportPdfPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Exporting PDF functionality coming soon!')),
                          );
                        },
                      ),
                      const SizedBox(height: 48),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              stateProvider.clearSession();
                              Navigator.of(context).pushReplacementNamed('/dashboard');
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Start New Patient Scan'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            ),
                          ),
                          const SizedBox(width: 16),
                          FilledButton.icon(
                            onPressed: () {
                               // Simulating saving to EHR
                               ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(content: Text('Saved to Patient EHR System.')),
                               );
                            },
                            icon: const Icon(Icons.save),
                            label: const Text('Commit to EHR'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
