import 'package:flutter/material.dart';

import '../../collimation/domain/collimation_workflow.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Guia de colimação')),
      body: SafeArea(
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: scheme.error.withValues(alpha: 0.12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.wb_sunny_outlined, color: scheme.error),
                  const SizedBox(width: 12),
                  Expanded(child: Text(kSafetyWarning)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Etapas', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...List.generate(CollimationWorkflowEngine.steps.length, (i) {
            final info = CollimationWorkflowEngine.steps[i];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: scheme.primary.withValues(alpha: 0.2),
                          child: Text('${i + 1}',
                              style: TextStyle(color: scheme.primary)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(info.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(info.objective,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic)),
                    const SizedBox(height: 6),
                    Text(info.instruction),
                    if (info.opticalNote != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: scheme.tertiary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline,
                                size: 16, color: scheme.tertiary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(info.opticalNote!,
                                  style: Theme.of(context).textTheme.bodySmall),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          Card(
            color: scheme.secondary.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: scheme.secondary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Este app é um assistente visual de colimação por '
                      'câmera do celular — não um colimador automático '
                      'perfeito. A precisão final depende do preview sem '
                      'distorção, dos círculos de referência e do '
                      'alinhamento físico do celular ao focalizador.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
