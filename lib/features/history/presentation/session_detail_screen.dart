import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/export/overlay_exporter.dart';
import '../application/session_providers.dart';
import '../domain/collimation_session.dart';

class SessionDetailScreen extends ConsumerWidget {
  final String sessionId;

  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Sessão')),
      body: SafeArea(
        child: sessions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erro: $e')),
          data: (list) {
            final session = list.where((s) => s.id == sessionId).firstOrNull;
            if (session == null) {
              return const Center(child: Text('Sessão não encontrada.'));
            }
            return _SessionBody(session: session);
          },
        ),
      ),
    );
  }
}

class _SessionBody extends StatelessWidget {
  final CollimationSession session;

  const _SessionBody({required this.session});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Iniciada em ${dateFmt.format(session.startedAt)}',
            style: Theme.of(context).textTheme.titleMedium),
        if (session.finishedAt != null)
          Text('Concluída em ${dateFmt.format(session.finishedAt!)}',
              style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Chip(label: Text(session.mode.label)),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _ImageTile(
                label: 'Antes',
                path: session.beforeImagePath,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ImageTile(
                label: 'Depois',
                path: session.afterImagePath,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (session.afterImagePath != null)
          FilledButton.icon(
            onPressed: () => _exportWithOverlay(context, session),
            icon: const Icon(Icons.ios_share),
            label: const Text('Exportar imagem com overlay'),
          ),
        if (session.notes != null && session.notes!.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Notas', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(session.notes!),
        ],
      ],
    );
  }

  Future<void> _exportWithOverlay(
      BuildContext context, CollimationSession session) async {
    final imagePath = session.afterImagePath ?? session.beforeImagePath;
    if (imagePath == null) return;
    final exporter = OverlayExporter();
    final path = await exporter.exportWithOverlay(
        imagePath, session.guides, 'export-${session.id}');
    if (context.mounted) {
      await Share.shareXFiles([XFile(path)]);
    }
  }
}

class _ImageTile extends StatelessWidget {
  final String label;
  final String? path;

  const _ImageTile({required this.label, required this.path});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: path == null
            ? Center(
                child: Text(label,
                    style: Theme.of(context).textTheme.bodySmall))
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(path!), fit: BoxFit.cover),
                  Positioned(
                    left: 6,
                    top: 6,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(label,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11)),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
