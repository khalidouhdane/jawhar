import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/services/ai_calibration_service.dart';
import 'package:quran_app/services/ai_plan_service.dart';

MemoryProfile _profile() => MemoryProfile(
  id: 'p1',
  name: 'Test',
  createdAt: DateTime(2026, 1, 1),
  startDate: DateTime(2026, 1, 1),
);

WeeklySnapshot _week() => WeeklySnapshot(
  startDate: DateTime(2026, 6, 1),
  endDate: DateTime(2026, 6, 7),
);

void main() {
  group('AIPlanService transport selection', () {
    test('flag off → callable path used, API never touched', () async {
      var apiCalls = 0;
      var callableCalls = 0;
      final service = AIPlanService(
        useApiV1Ai: false,
        apiBaseUrl: 'https://api.example.com',
        httpClient: MockClient((request) async {
          apiCalls++;
          return http.Response('{}', 200);
        }),
        idTokenProvider: () async => 'token-123',
        callableInvoker: (payload) async {
          callableCalls++;
          return {'plan': 'from-callable'};
        },
      );

      final result = await service.generatePlan(
        profile: _profile(),
        progressSnapshot: const {},
        recentSessions: const [],
        systemPromptOverride: 'prompt',
      );

      expect(apiCalls, 0);
      expect(callableCalls, 1);
      expect(result['plan'], 'from-callable');
    });

    test('flag on + empty base URL → treated as off, callable used', () async {
      var apiCalls = 0;
      var callableCalls = 0;
      final service = AIPlanService(
        useApiV1Ai: true,
        apiBaseUrl: '',
        httpClient: MockClient((request) async {
          apiCalls++;
          return http.Response('{}', 200);
        }),
        idTokenProvider: () async => 'token-123',
        callableInvoker: (payload) async {
          callableCalls++;
          return {'plan': 'from-callable'};
        },
      );

      final result = await service.generatePlan(
        profile: _profile(),
        progressSnapshot: const {},
        recentSessions: const [],
        systemPromptOverride: 'prompt',
      );

      expect(apiCalls, 0);
      expect(callableCalls, 1);
      expect(result['plan'], 'from-callable');
    });

    test(
      'flag on + base URL → API attempted with auth header, callable untouched',
      () async {
        http.Request? captured;
        var callableCalls = 0;
        final service = AIPlanService(
          useApiV1Ai: true,
          apiBaseUrl: 'https://api.example.com',
          httpClient: MockClient((request) async {
            captured = request;
            return http.Response(
              jsonEncode({'plan': 'from-api'}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
          idTokenProvider: () async => 'token-123',
          callableInvoker: (payload) async {
            callableCalls++;
            return {'plan': 'from-callable'};
          },
        );

        final result = await service.generatePlan(
          profile: _profile(),
          progressSnapshot: const {'memorizedPages': 3},
          recentSessions: const [],
          systemPromptOverride: 'prompt',
        );

        expect(captured, isNotNull);
        expect(captured!.method, 'POST');
        expect(
          captured!.url.toString(),
          'https://api.example.com/v1/me/plan:enhance',
        );
        expect(captured!.headers['authorization'], 'Bearer token-123');

        // Same request payload shape as the callable.
        final body = jsonDecode(captured!.body) as Map<String, dynamic>;
        expect(body['systemPrompt'], 'prompt');
        expect(body['isRecoveryMode'], false);
        expect((body['context'] as Map<String, dynamic>)['progress'], {
          'memorizedPages': 3,
        });

        expect(callableCalls, 0);
        expect(result['plan'], 'from-api');
      },
    );

    test('flag on + API HTTP error → falls back to callable', () async {
      var apiCalls = 0;
      var callableCalls = 0;
      final service = AIPlanService(
        useApiV1Ai: true,
        apiBaseUrl: 'https://api.example.com',
        httpClient: MockClient((request) async {
          apiCalls++;
          return http.Response('{"error":{"code":"internal"}}', 500);
        }),
        idTokenProvider: () async => 'token-123',
        callableInvoker: (payload) async {
          callableCalls++;
          return {'plan': 'from-callable'};
        },
      );

      final result = await service.generatePlan(
        profile: _profile(),
        progressSnapshot: const {},
        recentSessions: const [],
        systemPromptOverride: 'prompt',
      );

      expect(apiCalls, 1);
      expect(callableCalls, 1);
      expect(result['plan'], 'from-callable');
    });

    test('flag on + network exception → falls back to callable', () async {
      var callableCalls = 0;
      final service = AIPlanService(
        useApiV1Ai: true,
        apiBaseUrl: 'https://api.example.com',
        httpClient: MockClient((request) async {
          throw http.ClientException('connection refused');
        }),
        idTokenProvider: () async => 'token-123',
        callableInvoker: (payload) async {
          callableCalls++;
          return {'plan': 'from-callable'};
        },
      );

      final result = await service.generatePlan(
        profile: _profile(),
        progressSnapshot: const {},
        recentSessions: const [],
        systemPromptOverride: 'prompt',
      );

      expect(callableCalls, 1);
      expect(result['plan'], 'from-callable');
    });

    test('flag on + no ID token → API skipped, callable used', () async {
      var apiCalls = 0;
      var callableCalls = 0;
      final service = AIPlanService(
        useApiV1Ai: true,
        apiBaseUrl: 'https://api.example.com',
        httpClient: MockClient((request) async {
          apiCalls++;
          return http.Response('{}', 200);
        }),
        idTokenProvider: () async => null,
        callableInvoker: (payload) async {
          callableCalls++;
          return {'plan': 'from-callable'};
        },
      );

      final result = await service.generatePlan(
        profile: _profile(),
        progressSnapshot: const {},
        recentSessions: const [],
        systemPromptOverride: 'prompt',
      );

      expect(apiCalls, 0);
      expect(callableCalls, 1);
      expect(result['plan'], 'from-callable');
    });

    test('flag on + non-JSON API body → falls back to callable', () async {
      var callableCalls = 0;
      final service = AIPlanService(
        useApiV1Ai: true,
        apiBaseUrl: 'https://api.example.com',
        httpClient: MockClient((request) async {
          return http.Response('<html>gateway</html>', 200);
        }),
        idTokenProvider: () async => 'token-123',
        callableInvoker: (payload) async {
          callableCalls++;
          return {'plan': 'from-callable'};
        },
      );

      final result = await service.generatePlan(
        profile: _profile(),
        progressSnapshot: const {},
        recentSessions: const [],
        systemPromptOverride: 'prompt',
      );

      expect(callableCalls, 1);
      expect(result['plan'], 'from-callable');
    });

    test('both transports failing surfaces AIPlanException as today', () async {
      final service = AIPlanService(
        useApiV1Ai: true,
        apiBaseUrl: 'https://api.example.com',
        httpClient: MockClient((request) async {
          return http.Response('{}', 503);
        }),
        idTokenProvider: () async => 'token-123',
        callableInvoker: (payload) async {
          throw Exception('callable down');
        },
      );

      expect(
        () => service.generatePlan(
          profile: _profile(),
          progressSnapshot: const {},
          recentSessions: const [],
          systemPromptOverride: 'prompt',
        ),
        throwsA(isA<AIPlanException>()),
      );
    });
  });

  group('AICalibrationService transport selection', () {
    test('flag off → callable path used, API never touched', () async {
      var apiCalls = 0;
      var callableCalls = 0;
      final service = AICalibrationService(
        useApiV1Ai: false,
        apiBaseUrl: 'https://api.example.com',
        httpClient: MockClient((request) async {
          apiCalls++;
          return http.Response('{}', 200);
        }),
        idTokenProvider: () async => 'token-123',
        callableInvoker: (payload) async {
          callableCalls++;
          return {
            'suggestions': [
              {
                'type': 'increase_load',
                'iconKey': 'rocket',
                'title': 'Callable',
                'message': 'm',
                'reasoning': 'r',
              },
            ],
          };
        },
      );

      final suggestions = await service.generateCalibration(
        profile: _profile(),
        currentWeek: _week(),
        totalSessionCount: 7,
      );

      expect(apiCalls, 0);
      expect(callableCalls, 1);
      expect(suggestions, hasLength(1));
      expect(suggestions.single.title, 'Callable');
    });

    test(
      'flag on + base URL → API attempted with auth header, same parsing path',
      () async {
        http.Request? captured;
        var callableCalls = 0;
        final service = AICalibrationService(
          useApiV1Ai: true,
          apiBaseUrl: 'https://api.example.com',
          httpClient: MockClient((request) async {
            captured = request;
            return http.Response(
              jsonEncode({
                'suggestions': [
                  {
                    'type': 'more_review',
                    'iconKey': 'book',
                    'title': 'From API',
                    'message': 'm',
                    'reasoning': 'r',
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
          idTokenProvider: () async => 'token-456',
          callableInvoker: (payload) async {
            callableCalls++;
            return {'suggestions': []};
          },
        );

        final suggestions = await service.generateCalibration(
          profile: _profile(),
          currentWeek: _week(),
          totalSessionCount: 7,
        );

        expect(captured, isNotNull);
        expect(
          captured!.url.toString(),
          'https://api.example.com/v1/me/calibration:run',
        );
        expect(captured!.headers['authorization'], 'Bearer token-456');
        expect(callableCalls, 0);
        expect(suggestions, hasLength(1));
        expect(suggestions.single.type, SuggestionType.moreReview);
        expect(suggestions.single.title, 'From API');
      },
    );

    test('flag on + API failure → callable fallback', () async {
      var callableCalls = 0;
      final service = AICalibrationService(
        useApiV1Ai: true,
        apiBaseUrl: 'https://api.example.com',
        httpClient: MockClient((request) async {
          return http.Response('{}', 429);
        }),
        idTokenProvider: () async => 'token-123',
        callableInvoker: (payload) async {
          callableCalls++;
          return {
            'suggestions': [
              {
                'type': 'take_break',
                'iconKey': 'pause',
                'title': 'Callable fallback',
                'message': 'm',
                'reasoning': 'r',
              },
            ],
          };
        },
      );

      final suggestions = await service.generateCalibration(
        profile: _profile(),
        currentWeek: _week(),
        totalSessionCount: 7,
      );

      expect(callableCalls, 1);
      expect(suggestions, hasLength(1));
      expect(suggestions.single.title, 'Callable fallback');
    });

    test('both transports failing → empty list, as today', () async {
      final service = AICalibrationService(
        useApiV1Ai: true,
        apiBaseUrl: 'https://api.example.com',
        httpClient: MockClient((request) async {
          throw http.ClientException('connection refused');
        }),
        idTokenProvider: () async => 'token-123',
        callableInvoker: (payload) async {
          throw Exception('callable down');
        },
      );

      final suggestions = await service.generateCalibration(
        profile: _profile(),
        currentWeek: _week(),
        totalSessionCount: 7,
      );

      expect(suggestions, isEmpty);
    });
  });
}
