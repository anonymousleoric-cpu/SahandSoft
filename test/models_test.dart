import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sahandsoft/core/models.dart';

void main() {
  group('isSupportedUri', () {
    test('accepts known share schemes', () {
      expect(isSupportedUri('vmess://eyJhZGQiOiIxLjIuMy40In0='), isTrue);
      expect(isSupportedUri('VLESS://uuid@example.com:443?type=ws'), isTrue);
      expect(isSupportedUri('trojan://pass@host:443#node1'), isTrue);
      expect(isSupportedUri('ss://YWVzLTI1Ni1nY206cHc=@host:8388'), isTrue);
      expect(isSupportedUri('hysteria2://pass@host:443/'), isTrue);
    });

    test('rejects junk and unrelated schemes', () {
      expect(isSupportedUri(''), isFalse);
      expect(isSupportedUri('   '), isFalse);
      expect(isSupportedUri('https://example.com/sub'), isFalse);
      expect(isSupportedUri('hello world'), isFalse);
    });
  });

  group('decodeSubscriptionPayload', () {
    test('parses a plain newline separated list', () {
      const String payload = 'vmess://aaa\n\nvless://bbb\ntrojan://ccc';
      final List<String> result = decodeSubscriptionPayload(payload);
      expect(result, <String>['vmess://aaa', 'vless://bbb', 'trojan://ccc']);
    });

    test('parses a base64 encoded payload', () {
      const String plain = 'vmess://one\nvless://two';
      final String encoded = base64.encode(utf8.encode(plain));
      final List<String> result = decodeSubscriptionPayload(encoded);
      expect(result, <String>['vmess://one', 'vless://two']);
    });

    test('handles url-safe base64 without padding', () {
      const String plain = 'ss://onlyone';
      final String encoded =
          base64Url.encode(utf8.encode(plain)).replaceAll('=', '');
      final List<String> result = decodeSubscriptionPayload(encoded);
      expect(result, <String>['ss://onlyone']);
    });

    test('returns empty list for empty input', () {
      expect(decodeSubscriptionPayload(''), isEmpty);
      expect(decodeSubscriptionPayload('   \n '), isEmpty);
    });
  });

  group('deriveProfileId / deriveProfileLabel', () {
    test('id is stable for identical URIs and differs for others', () {
      const String a = 'vmess://same#nodeA';
      const String b = 'vmess://other#nodeB';
      expect(deriveProfileId(a), deriveProfileId(a));
      expect(deriveProfileId(a), isNot(deriveProfileId(b)));
    });

    test('label prefers the URI fragment', () {
      expect(deriveProfileLabel('vless://x@y:443#Frankfurt-01'),
          'Frankfurt-01');
    });

    test('label prefers host over userinfo, then fragment-free scheme', () {
      expect(deriveProfileLabel('vless://x@example.com:443'),
          'example.com');
      expect(deriveProfileLabel('ss://'), 'SS');
    });
  });
}
