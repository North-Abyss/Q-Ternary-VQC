import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ClinicalTriage { green, orange, red }

class GlassmorphicClinicalPanel extends StatelessWidget {
  final ClinicalTriage triage;
  final double confidenceScore; // e.g. 0.886
  final List<double> qutritProbabilities; // e.g. [0.05, 0.82, 0.13]
  final String diseaseDomain; // "Cardiovascular", "Neurological", "Oncology"
  final String clinicalInterpretation; // Plain-english text
  final VoidCallback? onExportPdfPressed;

  const GlassmorphicClinicalPanel({
    super.key,
    required this.triage,
    required this.confidenceScore,
    required this.qutritProbabilities,
    required this.diseaseDomain,
    required this.clinicalInterpretation,
    this.onExportPdfPressed,
  });

  Color get _triageColor {
    switch (triage) {
      case ClinicalTriage.green:
        return const Color(0xFF22C55E);
      case ClinicalTriage.orange:
        return const Color(0xFFF97316);
      case ClinicalTriage.red:
        return const Color(0xFFEF4444);
    }
  }

  String get _triageTitle {
    switch (triage) {
      case ClinicalTriage.green:
        return "Routine Screening / No Disease Detected";
      case ClinicalTriage.orange:
        return "Early Stage Warning / Action Required";
      case ClinicalTriage.red:
        return "Advanced Stage / High Risk Flag";
    }
  }

  IconData get _triageIcon {
    switch (triage) {
      case ClinicalTriage.green:
        return Icons.health_and_safety;
      case ClinicalTriage.orange:
        return Icons.warning_amber;
      case ClinicalTriage.red:
        return Icons.coronavirus;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B).withOpacity(0.4) : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2), // Simple translucent border for glass effect
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header & Triage Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          _PulsingIcon(icon: _triageIcon, color: _triageColor),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _triageTitle,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _triageColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _triageColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _triageColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        diseaseDomain.toUpperCase(),
                        style: TextStyle(
                          color: _triageColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 48),
                
                // Confidence Gauge Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Model Confidence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      '${(confidenceScore * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: _triageColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: confidenceScore),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: _triageColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: value,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              colors: [
                                _triageColor.withOpacity(0.6),
                                _triageColor,
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 48),
                
                // Qutrit Basis State Readout
                const Text('Qutrit Basis State Probabilities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(child: _buildQutritPill('|0⟩', qutritProbabilities.isNotEmpty ? qutritProbabilities[0] : 0.0, const Color(0xFF22C55E))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildQutritPill('|1⟩', qutritProbabilities.length > 1 ? qutritProbabilities[1] : 0.0, const Color(0xFFF97316))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildQutritPill('|2⟩', qutritProbabilities.length > 2 ? qutritProbabilities[2] : 0.0, const Color(0xFFEF4444))),
                  ],
                ),
                
                const SizedBox(height: 48),
                
                // Plain-English Narrative
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.summarize_outlined, size: 20, color: isDark ? Colors.white70 : Colors.black87),
                          const SizedBox(width: 12),
                          const Text('Clinical Interpretation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        clinicalInterpretation,
                        style: const TextStyle(height: 1.6, fontSize: 15),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: clinicalInterpretation));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Diagnostic summary copied to clipboard'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy Summary'),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? Colors.white70 : Colors.black87,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
                    if (onExportPdfPressed != null) ...[
                      const SizedBox(width: 16),
                      FilledButton.tonalIcon(
                        onPressed: onExportPdfPressed,
                        icon: const Icon(Icons.picture_as_pdf, size: 18),
                        label: const Text('Export PDF'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        ),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQutritPill(String label, double prob, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 20)),
          const SizedBox(height: 8),
          Text('P = ${prob.toStringAsFixed(3)}', style: TextStyle(color: color.withOpacity(0.9), fontSize: 14)),
        ],
      ),
    );
  }
}

class _PulsingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  const _PulsingIcon({required this.icon, required this.color});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_controller.value * 0.15), // Pulses smoothly
          child: Icon(widget.icon, color: widget.color, size: 40),
        );
      },
    );
  }
}
