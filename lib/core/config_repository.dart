import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Local persistence + import pipeline for VPN profiles.
///
/// The public BegzarApp source ships without its backend base-URL
/// (see README "Known limitations"), so SahandSoft edition manages configs
/// directly: manual share-URIs and standard V2Ray subscription URLs.
class ConfigRepository {
  ConfigRepository({SharedPreferences? prefs, Dio? dio})
      : _prefsOverride = prefs,
        _dio = dio;

  static const String _kProfiles = 'sahand_profiles_v1';
  static const String _kSelected = 'sahand_selected_profile_v1';
  static const String _kSubscription = 'sahand_subscription_url_v1';

  final SharedPreferences? _prefsOverride;
  final Dio? _dio;

  Future<SharedPreferences> _prefs() async =>
      _prefsOverride ?? SharedPreferences.getInstance();

  // ---- Profiles ------------------------------------------------------------

  Future<List<VpnProfile>> loadProfiles() async {
    final SharedPreferences prefs = await _prefs();
    final String raw = prefs.getString(_kProfiles) ?? '[]';
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(VpnProfile.fromJson)
          .toList();
    } catch (e) {
      debugPrint('ConfigRepository: corrupted profile store -> reset. $e');
      return <VpnProfile>[];
    }
  }

  Future<void> _saveProfiles(List<VpnProfile> profiles) async {
    final SharedPreferences prefs = await _prefs();
    await prefs.setString(
      _kProfiles,
      jsonEncode(profiles.map((VpnProfile p) => p.toJson()).toList()),
    );
  }

  /// Adds one profile from a raw share-URI. Returns null when the URI is not
  /// supported, otherwise the created profile.
  Future<VpnProfile?> addFromUri(String uri, {String? label}) async {
    if (!isSupportedUri(uri)) return null;
    final List<VpnProfile> profiles = await loadProfiles();
    final String id = deriveProfileId(uri);
    if (profiles.any((VpnProfile p) => p.id == id)) {
      return profiles.firstWhere((VpnProfile p) => p.id == id);
    }
    final VpnProfile profile = VpnProfile(
      id: id,
      label: (label == null || label.trim().isEmpty)
          ? deriveProfileLabel(uri)
          : label.trim(),
      uri: uri.trim(),
      source: 'manual',
    );
    profiles.add(profile);
    await _saveProfiles(profiles);
    return profile;
  }

  Future<void> removeProfile(String id) async {
    final List<VpnProfile> profiles = await loadProfiles();
    profiles.removeWhere((VpnProfile p) => p.id == id);
    await _saveProfiles(profiles);
    final String? selected = await getSelectedProfileId();
    if (selected == id) await setSelectedProfileId(null);
  }

  Future<void> updateDelay(String id, int? delayMs) async {
    final List<VpnProfile> profiles = await loadProfiles();
    final int index =
        profiles.indexWhere((VpnProfile p) => p.id == id);
    if (index == -1) return;
    profiles[index] = profiles[index].copyWith(lastDelayMs: delayMs);
    await _saveProfiles(profiles);
  }

  // ---- Selection -----------------------------------------------------------

  Future<String?> getSelectedProfileId() async {
    final SharedPreferences prefs = await _prefs();
    return prefs.getString(_kSelected);
  }

  Future<void> setSelectedProfileId(String? id) async {
    final SharedPreferences prefs = await _prefs();
    if (id == null) {
      await prefs.remove(_kSelected);
    } else {
      await prefs.setString(_kSelected, id);
    }
  }

  // ---- Subscription --------------------------------------------------------

  Future<String?> getSubscriptionUrl() async {
    final SharedPreferences prefs = await _prefs();
    return prefs.getString(_kSubscription);
  }

  Future<void> setSubscriptionUrl(String? url) async {
    final SharedPreferences prefs = await _prefs();
    if (url == null || url.trim().isEmpty) {
      await prefs.remove(_kSubscription);
    } else {
      await prefs.setString(_kSubscription, url.trim());
    }
  }

  /// Fetches the stored subscription and merges its URIs.
  /// Returns the number of newly added profiles.
  Future<int> refreshSubscription() async {
    final String? url = await getSubscriptionUrl();
    if (url == null || url.isEmpty) {
      throw const SubscriptionException('no_subscription');
    }
    return importSubscription(url);
  }

  /// Fetches [url], decodes the payload and merges new profiles.
  /// Returns the number of newly added profiles.
  Future<int> importSubscription(String url) async {
    final Uri parsed = Uri.tryParse(url.trim()) ?? Uri();
    if (parsed.scheme != 'http' && parsed.scheme != 'https') {
      throw const SubscriptionException('invalid_url');
    }
    final Dio client = _dio ?? Dio();
    final Response<dynamic> response = await client
        .get<String>(
          parsed.toString(),
          options: Options(responseType: ResponseType.plain),
        )
        .timeout(const Duration(seconds: 15));
    final String? body = response.data;
    if (body == null || body.isEmpty) {
      throw const SubscriptionException('empty_payload');
    }
    final List<String> uris = decodeSubscriptionPayload(body);
    if (uris.isEmpty) throw const SubscriptionException('no_valid_uri');

    int added = 0;
    for (final String uri in uris) {
      final String id = deriveProfileId(uri);
      final List<VpnProfile> existing = await loadProfiles();
      if (existing.any((VpnProfile p) => p.id == id)) continue;
      final VpnProfile? profile = await addFromUri(uri);
      if (profile != null) added++;
    }
    await setSubscriptionUrl(url);
    return added;
  }

  // ---- Excluded apps (kept from upstream behavior) -------------------------

  static const String kBlockedApps = 'blockedApps';

  Future<List<String>> loadBlockedApps() async {
    final SharedPreferences prefs = await _prefs();
    return prefs.getStringList(kBlockedApps) ?? <String>[];
  }

  Future<void> saveBlockedApps(List<String> packages) async {
    final SharedPreferences prefs = await _prefs();
    await prefs.setStringList(kBlockedApps, packages);
  }
}

/// Typed error for subscription import problems.
class SubscriptionException implements Exception {
  const SubscriptionException(this.code);
  final String code;

  @override
  String toString() => 'SubscriptionException($code)';
}
