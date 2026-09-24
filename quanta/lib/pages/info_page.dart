import 'package:flutter/material.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Q-Ternary VQC Info')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About Hybrid Quantum Machine Learning',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                
                _buildInfoCard(
                  context,
                  title: 'What is Q-Ternary Compression?',
                  icon: Icons.compress,
                  content: 'Q-Ternary losslessly compresses 3 classical bits into 2 qutrits (2³→3²). '
                      'This cuts quantum resource needs by 33% and keeps circuits shallow enough to run '
                      'on today\'s simulators. Entangled qutrits (CSUM gates) with per-layer data '
                      're-uploading capture nonlinear disease patterns.',
                ),
                const SizedBox(height: 16),
                
                _buildInfoCard(
                  context,
                  title: 'Why use this Platform?',
                  icon: Icons.memory,
                  content: 'Standard QML approaches crash hospital computers by mapping data directly onto qubits (OOM errors). '
                      'Our 2³→3² compression sidesteps this by design. This platform uses only 72 trainable '
                      'parameters vs. 1,000+ in classical alternatives, running on just 1.2 GB RAM.',
                ),
                const SizedBox(height: 16),
                
                _buildInfoCard(
                  context,
                  title: 'Clinical Diagnostic Workflow',
                  icon: Icons.medical_services_outlined,
                  content: '1. Patient Data Intake (Pipeline): Securely upload the patient\'s EHR or Genomic biomarker profile (CSV).\n'
                      '2. Diagnostic Training: The quantum model establishes a patient-specific baseline to identify pathological patterns.\n'
                      '3. Clinical Assessment (Inference): Run the patient\'s real-time metrics through the trained quantum model to generate a risk triage report.\n'
                      '4. Reporting (Dashboard): Review historical patient assessments and securely export diagnostic artifacts for compliance.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {required String title, required IconData icon, required String content}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
