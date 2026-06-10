import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/services/audio_proxy_server.dart';

void main() {
  test('allows HTTPS audio URLs on approved hosts and subdomains', () {
    expect(
      AudioProxyServer.isAllowedTarget(
        Uri.parse('https://server11.mp3quran.net/koshi/001.mp3'),
      ),
      isTrue,
    );
    expect(
      AudioProxyServer.isAllowedTarget(
        Uri.parse('https://audio.qurancdn.com/file.mp3'),
      ),
      isTrue,
    );
  });

  test('rejects non-HTTPS, credentialed, and unknown targets', () {
    expect(
      AudioProxyServer.isAllowedTarget(
        Uri.parse('http://audio.qurancdn.com/file.mp3'),
      ),
      isFalse,
    );
    expect(
      AudioProxyServer.isAllowedTarget(
        Uri.parse('https://user:pass@audio.qurancdn.com/file.mp3'),
      ),
      isFalse,
    );
    expect(
      AudioProxyServer.isAllowedTarget(
        Uri.parse('https://example.com/file.mp3'),
      ),
      isFalse,
    );
  });

  test('rejects loopback, private, and link-local resolved addresses', () {
    expect(
      AudioProxyServer.isPublicAddress(InternetAddress('127.0.0.1')),
      isFalse,
    );
    expect(
      AudioProxyServer.isPublicAddress(InternetAddress('10.1.2.3')),
      isFalse,
    );
    expect(
      AudioProxyServer.isPublicAddress(InternetAddress('172.16.0.1')),
      isFalse,
    );
    expect(
      AudioProxyServer.isPublicAddress(InternetAddress('192.168.1.1')),
      isFalse,
    );
    expect(
      AudioProxyServer.isPublicAddress(InternetAddress('169.254.1.1')),
      isFalse,
    );
    expect(
      AudioProxyServer.isPublicAddress(InternetAddress('100.64.0.1')),
      isFalse,
    );
    expect(AudioProxyServer.isPublicAddress(InternetAddress('::1')), isFalse);
    expect(
      AudioProxyServer.isPublicAddress(InternetAddress('fc00::1')),
      isFalse,
    );
    expect(
      AudioProxyServer.isPublicAddress(InternetAddress('142.250.74.110')),
      isTrue,
    );
    expect(
      AudioProxyServer.isPublicAddress(InternetAddress('2001:4860:4860::8888')),
      isTrue,
    );
  });
}
