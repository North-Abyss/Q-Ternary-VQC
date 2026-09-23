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
                  title: 'How to use this Application',
                  icon: Icons.help_outline,
                  content: '1. Data Setup: Upload a CSV dataset (e.g., Breast Cancer or CKD).\n'
                      '2. Training: Select Hyperparameters (Epochs, VQC Layers) and start the training job. Watch live cluster logs.\n'
                      '3. Inference: Use the trained PyTorch state dictionaries to make rapid batch predictions.\n'
                      '4. Dashboard: Download generated artifacts (.pt, .pkl).',
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
