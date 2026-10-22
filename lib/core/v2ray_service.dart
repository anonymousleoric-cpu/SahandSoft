import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:flutter_v2ray/model/v2ray_status.dart';

/// Thin, UI-independent wrapper around the flutter_v2ray engine.
///
/// The plugin API calls mirror the upstream BegzarApp usage exactly:
/// initializeV2Ray / requestPermission / startV2Ray / stopV2Ray /
/// getConnectedServerDelay / getAllServerDelay / parseFromURL.
/// Keeping them here separates VPN logic from widgets (mission §10).
class V2RayService {
  V2RayService();

  final ValueNotifier<V2RayStatus> status =
      ValueNotifier<V2RayStatus>(V2RayStatus());

  FlutterV2ray? _engine;
  bool _initialized = false;

  /// The notification button label must be provided before [initialize].
  String notificationDisconnectLabel = 'Disconnect';

  Future<void> initialize() async {
    if (_initialized) return;
    final FlutterV2ray engine = FlutterV2ray(
      onStatusChanged: (V2RayStatus value) {
        status.value = value;
      },
    );
    await engine.initializeV2Ray(
      notificationIconResourceType: 'drawable',
      notificationIconResourceName: 'notification_icon',
    );
    _engine = engine;
    _initialized = true;
  }

  Future<String?> coreVersion() async {
    if (!_initialized) return null;
    try {
      return await _engine!.getCoreVersion();
    } catch (e) {
      debugPrint('V2RayService.coreVersion failed: $e');
      return null;
    }
  }

  bool get isInitialized => _initialized;

  String get state => status.value.state;

  /// Requests the Android VPN permission dialog. True when granted.
  Future<bool> requestPermission() async {
    _ensureEngine();
    return _engine!.requestPermission();
  }

  /// Starts the VPN service with a full Xray JSON configuration.
  Future<void> start({
    required String remark,
    required String config,
    required List<String> blockedApps,
  }) async {
    _ensureEngine();
    await _engine!.startV2Ray(
      remark: remark,
      config: config,
      proxyOnly: false,
      bypassSubnets: null,
      notificationDisconnectButtonName: notificationDisconnectLabel,
      blockedApps: blockedApps,
    );
  }

  Future<void> stop() async {
    _ensureEngine();
    await _engine!.stopV2Ray();
  }

  /// Real measured delay of the currently connected server (ms), or null.
  Future<int?> connectedDelay() async {
    if (!_initialized) return null;
    try {
      return await _engine!.getConnectedServerDelay();
    } catch (e) {
      debugPrint('V2RayService.connectedDelay failed: $e');
      return null;
    }
  }

  /// Measures real delays for a list of full JSON configurations.
  /// Returns a map of config-JSON -> delay(ms). -1 means unreachable.
  Future<Map<String, int>> allDelays(List<String> fullConfigs) async {
    _ensureEngine();
    final String raw =
        await _engine!.getAllServerDelay(configs: fullConfigs);
    final Map<String, dynamic> decoded =
        jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map<String, int>(
      (String key, dynamic value) => MapEntry<String, int>(
        key,
        value is num ? value.toInt() : -1,
      ),
    );
  }

  /// Converts a share-URI into a full Xray JSON config (plugin parser).
  String fullConfigFromUri(String uri) {
    final V2RayURL parsed = FlutterV2ray.parseFromURL(uri);
    return parsed.getFullConfiguration();
  }

  void _ensureEngine() {
    if (!_initialized || _engine == null) {
      throw StateError('V2RayService is not initialized');
    }
  }

  /// No-op disposal placeholder — the engine is app-scoped.
  void dispose() {
    status.dispose();
  }
}
