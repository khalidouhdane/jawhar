// AI plan validator — moved to packages/hifz_core (shared with the
// jawhar-api server, which validates Vertex AI responses with the same
// safety rails). This shim keeps every existing
// `package:quran_app/services/ai_plan_validator.dart` import working
// unchanged.

export 'package:hifz_core/hifz_core.dart'
    show AIPlanValidator, AIValidationException;
