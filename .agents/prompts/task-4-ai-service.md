# Task 4: AIPlanService + Gemini 3.1 Integration

## Context
You are working on the Le Quran Flutter app — a Quran memorization companion.
Project root: `c:\Users\khali\OneDrive\Bureau\Quran App`

## What Was Already Done (task-1)
The `MemoryProfile` model in `lib/models/hifz_models.dart` has all the fields needed for AI context:
- `age`, `ageGroup` (7 values), `encodingSpeed`, `retentionStrength`, `learningPreference`
- `dailyTimeMinutes`, `activeDays`, `pacePreference`, `hifzExperience`
- `goal`, `goalDetails`, `startingPage`

## Your Task
Create a new `AIPlanService` that integrates with Gemini 3.1 for AI-powered plan generation.

### 1. Add Dependency
Add `google_generative_ai` package to `pubspec.yaml`:
```yaml
google_generative_ai: ^0.4.6
```
Run `flutter pub get`.

### 2. Create `lib/services/ai_plan_service.dart`

```dart
class AIPlanService {
  // Bundled API key (dev phase only)
  static const _apiKey = 'AIzaSyD...'; // User will provide
  
  // Model options
  static const _flashModel = 'gemini-2.0-flash'; // Default
  static const _proModel = 'gemini-2.0-pro';     // Optional
  
  String _activeModelName;
  GenerativeModel? _model;
  
  // Constructor
  AIPlanService({String? model}) : _activeModelName = model ?? _flashModel;
  
  // Switch model (for dev testing)
  void setModel(String modelName) { ... }
  
  // Build user context JSON from profile + progress + session history
  Map<String, dynamic> buildUserContext({
    required MemoryProfile profile,
    required Map<String, dynamic> progressSnapshot,
    required List<Map<String, dynamic>> recentSessions,
  }) { ... }
  
  // Generate daily plan via Gemini
  Future<Map<String, dynamic>> generatePlan({
    required MemoryProfile profile,
    required Map<String, dynamic> progressSnapshot,
    required List<Map<String, dynamic>> recentSessions,
    required String systemPrompt,
    bool isRecoveryMode = false,
  }) async { ... }
}
```

### 3. buildUserContext() Implementation
Assemble a JSON map containing:
- `profile`: age, ageGroup name, encodingSpeed name, retentionStrength name, learningPreference name, dailyTimeMinutes, activeDays, pacePreference name, hifzExperience name, goal name, startingPage
- `progress`: pagesMemorized count, pagesLearning count, currentPage, completedJuz list, streakDays
- `recentSessions`: last 7 sessions with date, assessments, duration, reps
- `todayIs`: day of week name
- `isActiveDay`: whether today is in activeDays

### 4. generatePlan() Implementation
- Load system prompt from `assets/prompts/plan_system_prompt_v1.md` (will be created in task-5)
- Create GenerativeModel with the active model name
- Set `generationConfig` with:
  - responseMimeType: 'application/json'
  - temperature: 0.3
  - maxOutputTokens: 4096
- Send system prompt + user context JSON as the prompt
- Parse JSON response
- Return the parsed map (validation will be in task-6)

### 5. Model Switcher in Profile Settings
Add a simple model toggle to `lib/screens/profile_screen.dart`:
- A dropdown or segmented control: "AI Model: Flash / Pro"
- Persisted via SharedPreferences key `ai_model`
- Load on app start

### 6. Error Handling
- Timeout: 15 seconds max
- Network error → throw descriptive exception
- Invalid response → throw with raw response for debugging
- Rate limit → throw with retry suggestion

### Important:
- Read AGENTS.md and GEMINI.md for project architecture context
- For the API key: use a placeholder string like `'YOUR_GEMINI_API_KEY'` — the user will set the real key
- Use the `google_generative_ai` package's `GenerativeModel` class
- The system prompt file won't exist yet — handle gracefully (use a basic fallback prompt)
- Store model preference in SharedPreferences

## Acceptance Criteria
- `google_generative_ai` added to pubspec.yaml
- `AIPlanService` class created with Flash/Pro model support
- `buildUserContext()` assembles complete profile + progress + sessions JSON
- `generatePlan()` calls Gemini API with structured JSON output
- Model switcher added to profile settings
- Error handling for timeout, network, invalid response
- No compilation errors (run `dart analyze`)
