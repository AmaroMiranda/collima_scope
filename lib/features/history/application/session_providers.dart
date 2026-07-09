import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_store.dart';
import '../domain/collimation_session.dart';

final sessionStoreProvider = Provider<JsonListStore<CollimationSession>>(
  (ref) => JsonListStore(
    key: 'collimation_sessions',
    toJson: (s) => s.toJson(),
    fromJson: CollimationSession.fromJson,
    idOf: (s) => s.id,
  ),
);

class SessionsNotifier extends AsyncNotifier<List<CollimationSession>> {
  @override
  Future<List<CollimationSession>> build() async {
    final all = await ref.watch(sessionStoreProvider).loadAll();
    all.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return all;
  }

  Future<void> save(CollimationSession session) async {
    await ref.read(sessionStoreProvider).upsert(session);
    ref.invalidateSelf();
  }

  Future<void> remove(String id) async {
    await ref.read(sessionStoreProvider).delete(id);
    ref.invalidateSelf();
  }
}

final sessionsProvider =
    AsyncNotifierProvider<SessionsNotifier, List<CollimationSession>>(
        SessionsNotifier.new);
