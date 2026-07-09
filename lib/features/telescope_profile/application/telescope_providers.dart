import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_store.dart';
import '../domain/telescope_profile.dart';

final telescopeStoreProvider = Provider<JsonListStore<TelescopeProfile>>(
  (ref) => JsonListStore(
    key: 'telescope_profiles',
    toJson: (t) => t.toJson(),
    fromJson: TelescopeProfile.fromJson,
    idOf: (t) => t.id,
  ),
);

class TelescopesNotifier extends AsyncNotifier<List<TelescopeProfile>> {
  @override
  Future<List<TelescopeProfile>> build() =>
      ref.watch(telescopeStoreProvider).loadAll();

  Future<void> save(TelescopeProfile profile) async {
    await ref.read(telescopeStoreProvider).upsert(profile);
    ref.invalidateSelf();
  }

  Future<void> remove(String id) async {
    await ref.read(telescopeStoreProvider).delete(id);
    ref.invalidateSelf();
  }
}

final telescopesProvider =
    AsyncNotifierProvider<TelescopesNotifier, List<TelescopeProfile>>(
        TelescopesNotifier.new);
