import * as functions from 'firebase-functions/v2';
import { GoogleGenAI } from '@google/genai';
import { hasCallableAuthentication } from './security';

// Vertex AI via the runtime service account (ADC) — no API key.
// Model is config, not code: override with the GEMINI_MODEL env var.
const MODEL_NAME = process.env.GEMINI_MODEL ?? 'gemini-3.5-flash';
const VERTEX_LOCATION = process.env.VERTEX_LOCATION ?? 'global';

function requireAuthentication(request: functions.https.CallableRequest) {
  if (!hasCallableAuthentication(request.auth)) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated.'
    );
  }
}

/**
 * Common helper to initialize the Gen AI client (Vertex AI, ADC-authenticated)
 */
function getAiClient() {
  const project = process.env.GCLOUD_PROJECT;
  if (!project) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'GCLOUD_PROJECT is not set in the runtime environment.'
    );
  }
  return new GoogleGenAI({ vertexai: true, project, location: VERTEX_LOCATION });
}

/**
 * Callable function to generate a daily plan.
 */
export const generateDailyPlan = functions.https.onCall(
  {
    region: 'europe-west1',
    enforceAppCheck: false, // Set to true if AppCheck is configured
  },
  async (request) => {
    requireAuthentication(request);

    const data = request.data;
    if (!data.context) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing "context" in request data.');
    }

    const { context, isRecoveryMode, systemPrompt } = data;
    const contextJson = JSON.stringify(context, null, 2);

    let userMessage = '';
    if (isRecoveryMode) {
      userMessage = `RECOVERY MODE: The user has returned after missed days.\nGenerate a lighter, review-focused plan to ease them back in.\n\nUser Context:\n${contextJson}\n\nGenerate the daily plan as JSON.`;
    } else {
      userMessage = `Generate today's memorization plan based on this user context:\n\n${contextJson}\n\nGenerate the daily plan as JSON.`;
    }

    try {
      const ai = getAiClient();
      const response = await ai.models.generateContent({
        model: MODEL_NAME,
        contents: userMessage,
        config: {
          systemInstruction: systemPrompt || 'You are a Quran memorization (Hifz) planning assistant. Generate a daily plan based on the user\'s profile and progress. Return valid JSON only.',
          responseMimeType: 'application/json',
          temperature: 0.3,
        },
      });

      const text = response.text;
      if (!text || text.trim() === '') {
        throw new functions.https.HttpsError('internal', 'AI returned empty response.');
      }

      return JSON.parse(text);
    } catch (error: any) {
      console.error('Error generating plan:', error);
      throw new functions.https.HttpsError('internal', `AI generation failed: ${error.message}`);
    }
  }
);

/**
 * Callable function to generate weekly calibrations.
 */
export const generateCalibration = functions.https.onCall(
  {
    region: 'europe-west1',
    enforceAppCheck: false,
  },
  async (request) => {
    requireAuthentication(request);

    const data = request.data;
    if (!data.context) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing "context" in request data.');
    }

    const { context, systemPrompt } = data;
    const contextJson = JSON.stringify(context, null, 2);
    const userMessage = `Generate today's memorization plan based on this user context:\n\n${contextJson}\n\nGenerate the daily plan as JSON.`;

    try {
      const ai = getAiClient();
      const response = await ai.models.generateContent({
        model: MODEL_NAME,
        contents: userMessage,
        config: {
          systemInstruction: systemPrompt || 'You are a Quran memorization (Hifz) coach analyzing a student\'s weekly performance.',
          responseMimeType: 'application/json',
          temperature: 0.3,
        },
      });

      const text = response.text;
      if (!text || text.trim() === '') {
        throw new functions.https.HttpsError('internal', 'AI returned empty response.');
      }

      return JSON.parse(text);
    } catch (error: any) {
      console.error('Error generating calibration:', error);
      throw new functions.https.HttpsError('internal', `AI generation failed: ${error.message}`);
    }
  }
);
