/// Domain models for the SahandSoft VPN client.
library;

import 'dart:convert';

/// A single VPN profile (one V2Ray share-URI).
class VpnProfile {
  const VpnProfile({
    required this.id,
    required this.label,
    required this.uri,
    required this.source,
    this.lastDelayMs,
  });

  /// Stable id — derived from the URI content (see [VpnProfileIds.derive]).
  final String id;

  /// Human readable label (parsed remark or user supplied).
  final String label;

  /// Raw share URI: vmess://, vless://, trojan://, ss:// ...
  final String uri;

  /// Where the profile came from: 'manual' or 'sub:<hash>'.
  final String source;

  /// Last measured real latency in ms (null = not measured yet / failed).
  final int? lastDelayMs;

  VpnProfile copyWith({String? label, int? lastDelayMs}) => VpnProfile(
        id: id,
        label: label,
        uri: uri,
        source: source,
        lastDelayMs: lastDelayMs,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'label': label,
        'uri': uri,
        'source': source,
        if (lastDelayMs != null) 'lastDelayMs': lastDelayMs,
      };

  factory VpnProfile.fromJson(Map<String, dynamic> json) => VpnProfile(
        id: json['id'] as String,
        label: (json['label'] ?? '') as String,
        uri: json['uri'] as String,
        source: (json['source'] ?? 'manual') as String,
        lastDelayMs: json['lastDelayMs'] == null
            ? null
            : (json['lastDelayMs'] as num).toInt(),
      );
}

/// Supported share-URI schemes.
const List<String> kSupportedSchemes = <String>[
  'vmess://',
  'vless://',
  'trojan://',
  'ss://',
  'ssr://',
  'hysteria2://',
  'hy2://',
  'tuic://',
];

/// Returns true when [uri] starts with one of the supported schemes.
bool isSupportedUri(String uri) {
  final String trimmed = uri.trim();
  if (trimmed.isEmpty) return false;
  for (final String scheme in kSupportedSchemes) {
    if (trimmed.toLowerCase().startsWith(scheme)) return true;
  }
  return false;
}

/// Decodes a V2Ray subscription payload into raw share-URI strings.
///
/// Standard subscriptions are a base64 (url-safe, unpadded tolerated) blob of
/// newline separated share-URIs; plain-text lists are accepted as fallback.
/// Pure Dart — safe for unit tests.
List<String> decodeSubscriptionPayload(String payload) {
  final String trimmed = payload.trim();
  if (trimmed.isEmpty) return <String>[];

  String body = trimmed;
  if (!trimmed.toLowerCase().contains('://')) {
    // Likely base64 — normalize then try to decode.
    try {
      final String normalized =
          trimmed.replaceAll('-', '+').replaceAll('_', '/').trim();
      final String padded =
          normalized + '=' * ((4 - normalized.length % 4) % 4);
      body = utf8.decode(base64.decode(padded));
    } on FormatException {
      body = trimmed;
    } on ArgumentError {
      body = trimmed;
    }
  }

  final List<String> result = <String>[];
  for (var line in LineSplitter.split(body)) {
    line = line.trim();
    if (isSupportedUri(line)) result.add(line);
  }
  return result;
}

/// Derives a stable profile id from a URI (djb2 over base64 of the uri).
String deriveProfileId(String uri) {
  final List<int> bytes = utf8.encode(uri.trim());
  int hash = 5381;
  for (final int b in bytes) {
    hash = ((hash << 5) + hash + b) & 0x7fffffff;
  }
  return 'p$hash';
}

/// Extracts a friendly label from a share URI without external deps.
String deriveProfileLabel(String uri) {
  final String trimmed = uri.trim();
  try {
    final Uri parsed = Uri.parse(trimmed);
    if (parsed.fragment.isNotEmpty && parsed.fragment.length <= 48) {
      return Uri.decodeComponent(parsed.fragment);
    }
    if (parsed.host.isNotEmpty) return parsed.host;
    if (parsed.userInfo.isNotEmpty) return parsed.userInfo;
  } on FormatException {
    // fall through
  }
  final String scheme = trimmed.split('://').first;
  return scheme.toUpperCase();
}
