import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_store.dart';
import '../domain/adapter_profile.dart';

final adapterStoreProvider = Provider<JsonListStore<AdapterProfile>>(
  (ref) => JsonListStore(
    key: 'adapter_profiles',
    toJson: (a) => a.toJson(),
    fromJson: AdapterProfile.fromJson,
    idOf: (a) => a.id,
  ),
);

class AdaptersNotifier extends AsyncNotifier<List<AdapterProfile>> {
  @override
  Future<List<AdapterProfile>> build() =>
      ref.watch(adapterStoreProvider).loadAll();

  Future<void> save(AdapterProfile profile) async {
    await ref.read(adapterStoreProvider).upsert(profile);
    ref.invalidateSelf();
  }

  Future<void> remove(String id) async {
    await ref.read(adapterStoreProvider).delete(id);
    ref.invalidateSelf();
  }
}

final adaptersProvider =
    AsyncNotifierProvider<AdaptersNotifier, List<AdapterProfile>>(
        AdaptersNotifier.new);
