import 'dart:convert';
import 'dart:io';

const String baseUrl = 'https://apis.quran.foundation/content/api/v4';

String stripHtml(String html) {
  if (html.isEmpty) return '';
  return html
      .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'</div>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'</h[1-6]>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&nbsp;', ' ')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .replaceAll(RegExp(r' {2,}'), ' ')
      .trim();
}

Future<void> fetchResource(
  int resourceId,
  String resourceType,
  String outputFile,
  String token,
  String clientId,
) async {
  print('Fetching $resourceType $resourceId...');
  final results = <String, String>{};

  final futures = <Future<void>>[];

  for (int page = 1; page <= 604; page++) {
    futures.add(() async {
      final uri = Uri.parse(
        '$baseUrl/verses/by_page/$page?$resourceType=$resourceId&per_page=50',
      );

      bool success = false;
      for (int attempt = 0; attempt < 15; attempt++) {
        // Fresh client per request to avoid BoringSSL caching errors on Windows
        final client = HttpClient();
        try {
          final request = await client
              .getUrl(uri)
              .timeout(const Duration(seconds: 15));
          request.headers.add('x-auth-token', token);
          request.headers.add('x-client-id', clientId);

          final response = await request.close().timeout(
            const Duration(seconds: 15),
          );
          if (response.statusCode == 200) {
            final responseBody = await response.transform(utf8.decoder).join();
            final data = json.decode(responseBody);
            final verses = data['verses'] as List<dynamic>?;
            if (verses != null) {
              for (final v in verses) {
                final vk = v['verse_key'] as String?;
                final items = v[resourceType] as List<dynamic>?;
                if (vk != null && items != null && items.isNotEmpty) {
                  final text = items.first['text'] as String? ?? '';
                  results[vk] = stripHtml(text);
                }
              }
            }
            success = true;
            break;
          } else {
            // print('Failed $uri: ${response.statusCode}');
          }
        } catch (e) {
          // print('Error $uri: $e');
        } finally {
          client.close(force: true);
        }
      }
      if (!success) {
        print('Failed completely for page $page');
      }
    }());

    if (page % 5 == 0 || page == 604) {
      await Future.wait(futures);
      futures.clear();
      print('Completed $page/604 pages for $resourceId...');
    }
  }

  final sortedKeys = results.keys.toList()
    ..sort((a, b) {
      final pa = a.split(':');
      final pb = b.split(':');
      final ca = int.parse(pa[0]);
      final cb = int.parse(pb[0]);
      if (ca != cb) return ca.compareTo(cb);
      return int.parse(pa[1]).compareTo(int.parse(pb[1]));
    });

  final sortedResults = <String, String>{};
  for (final key in sortedKeys) {
    sortedResults[key] = results[key]!;
  }

  final file = File(outputFile);
  await file.create(recursive: true);
  await file.writeAsString(json.encode(sortedResults));
  print('Saved ${sortedResults.length} verses to $outputFile');
}

void main() async {
  final envFile = File('.env');
  String clientId = '';
  String clientSecret = '';
  if (await envFile.exists()) {
    final lines = await envFile.readAsLines();
    for (final line in lines) {
      if (line.startsWith('QURAN_API_CLIENT_ID=')) {
        clientId = line.split('=')[1].trim();
      } else if (line.startsWith('QURAN_API_CLIENT_SECRET=')) {
        clientSecret = line.split('=')[1].trim();
      }
    }
  } else {
    print('Error: .env file not found.');
    return;
  }

  print('Authenticating...');
  final authUri = Uri.parse('https://oauth2.quran.foundation/oauth2/token');
  final authStr = base64Encode(utf8.encode('$clientId:$clientSecret'));
  String token = '';

  for (int attempt = 0; attempt < 10; attempt++) {
    final authClient = HttpClient();
    try {
      final authRequest = await authClient.postUrl(authUri);
      authRequest.headers.add(
        'Content-Type',
        'application/x-www-form-urlencoded',
      );
      authRequest.headers.add('Authorization', 'Basic $authStr');
      authRequest.write('grant_type=client_credentials&scope=content');
      final authResponse = await authRequest.close();
      if (authResponse.statusCode == 200) {
        final authBody = await authResponse.transform(utf8.decoder).join();
        token = json.decode(authBody)['access_token'];
        authClient.close(force: true);
        break;
      }
    } catch (e) {
      // Retry on SSL or other errors
      print('Auth retry ${attempt + 1}');
    } finally {
      authClient.close(force: true);
    }
  }

  if (token.isEmpty) {
    print('Failed to authenticate.');
    return;
  }
  print('Authenticated successfully.');

  final targetDir = 'assets/data/translations';
  await fetchResource(
    85,
    'translations',
    '$targetDir/en_85.json',
    token,
    clientId,
  );
  await fetchResource(16, 'tafsirs', '$targetDir/ar_16.json', token, clientId);

  exit(0);
}
