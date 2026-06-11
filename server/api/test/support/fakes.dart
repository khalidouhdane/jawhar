import 'package:jawhar_api/ai/vertex_client.dart';
import 'package:jawhar_api/quota/ai_quota.dart';

/// Records a single [FakeVertexClient.generateContent] invocation.
class VertexCall {
  VertexCall({
    required this.model,
    required this.userText,
    required this.systemInstruction,
    required this.temperature,
    required this.responseMimeType,
  });

  final String model;
  final String userText;
  final String? systemInstruction;
  final double temperature;
  final String responseMimeType;
}

/// Scriptable [VertexClient] for handler tests: returns [textToReturn] or
/// throws [errorToThrow], recording every call. Never touches ADC or the
/// network (the base class only creates its HTTP client lazily on a real
/// request, which this override never makes).
class FakeVertexClient extends VertexClient {
  FakeVertexClient({this.textToReturn = '{}', this.errorToThrow})
      : super(projectId: 'test-project');

  String textToReturn;
  Object? errorToThrow;
  final List<VertexCall> calls = [];

  @override
  Future<String> generateContent({
    required String model,
    required String userText,
    String? systemInstruction,
    double temperature = 0.3,
    String responseMimeType = 'application/json',
  }) async {
    calls.add(VertexCall(
      model: model,
      userText: userText,
      systemInstruction: systemInstruction,
      temperature: temperature,
      responseMimeType: responseMimeType,
    ));
    final error = errorToThrow;
    if (error != null) throw error;
    return textToReturn;
  }
}

/// Records a single [FakeAiQuota.tryConsume] invocation.
class QuotaCall {
  QuotaCall({required this.uid, required this.localDate});
  final String uid;
  final String localDate;
}

/// In-memory [AiQuota] for handler tests; set [exhausted] to script a 429.
class FakeAiQuota implements AiQuota {
  FakeAiQuota({this.exhausted = false, this.limit = 10});

  bool exhausted;
  final int limit;
  final List<QuotaCall> calls = [];

  @override
  Future<QuotaDecision> tryConsume({
    required String uid,
    required String localDate,
  }) async {
    calls.add(QuotaCall(uid: uid, localDate: localDate));
    if (exhausted) {
      return QuotaDecision(allowed: false, limit: limit, remaining: 0);
    }
    return QuotaDecision(
      allowed: true,
      limit: limit,
      remaining: limit - calls.length,
    );
  }
}
