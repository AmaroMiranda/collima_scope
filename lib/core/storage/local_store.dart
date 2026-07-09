import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Repositório genérico de listas JSON em SharedPreferences.
/// Suficiente para o MVP (perfis e sessões são poucos e pequenos).
class JsonListStore<T> {
  final String key;
  final Map<String, dynamic> Function(T) toJson;
  final T Function(Map<String, dynamic>) fromJson;
  final String Function(T) idOf;

  JsonListStore({
    required this.key,
    required this.toJson,
    required this.fromJson,
    required this.idOf,
  });

  Future<List<T>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList(growable: true);
  }

  Future<void> saveAll(List<T> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        key, jsonEncode(items.map(toJson).toList(growable: false)));
  }

  Future<void> upsert(T item) async {
    final items = await loadAll();
    final index = items.indexWhere((e) => idOf(e) == idOf(item));
    if (index >= 0) {
      items[index] = item;
    } else {
      items.add(item);
    }
    await saveAll(items);
  }

  Future<void> delete(String id) async {
    final items = await loadAll();
    items.removeWhere((e) => idOf(e) == id);
    await saveAll(items);
  }
}

/// Preferências simples do app.
class AppPrefs {
  static const _safetyAcceptedKey = 'safety_accepted';
  static const _previewCalibratedKey = 'preview_calibrated';
  static const _redModeKey = 'red_mode';
  static const _lastTelescopeKey = 'last_telescope_id';
  static const _lastAdapterKey = 'last_adapter_id';

  Future<bool> getSafetyAccepted() async =>
      (await SharedPreferences.getInstance()).getBool(_safetyAcceptedKey) ??
      false;

  Future<void> setSafetyAccepted(bool value) async =>
      (await SharedPreferences.getInstance())
          .setBool(_safetyAcceptedKey, value);

  Future<bool> getPreviewCalibrated() async =>
      (await SharedPreferences.getInstance()).getBool(_previewCalibratedKey) ??
      false;

  Future<void> setPreviewCalibrated(bool value) async =>
      (await SharedPreferences.getInstance())
          .setBool(_previewCalibratedKey, value);

  Future<bool> getRedMode() async =>
      (await SharedPreferences.getInstance()).getBool(_redModeKey) ?? false;

  Future<void> setRedMode(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(_redModeKey, value);

  Future<String?> getLastTelescopeId() async =>
      (await SharedPreferences.getInstance()).getString(_lastTelescopeKey);

  Future<void> setLastTelescopeId(String id) async =>
      (await SharedPreferences.getInstance()).setString(_lastTelescopeKey, id);

  Future<String?> getLastAdapterId() async =>
      (await SharedPreferences.getInstance()).getString(_lastAdapterKey);

  Future<void> setLastAdapterId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_lastAdapterKey);
    } else {
      await prefs.setString(_lastAdapterKey, id);
    }
  }
}

String newId() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${_counter++}';
int _counter = 0;
