import * as functions from 'firebase-functions/v2';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { defineString } from 'firebase-functions/params';

// Optional: you can switch to defineSecret if using Firebase Secret Manager
const GEMINI_API_KEY = defineString('GEMINI_API_KEY');

const MODEL_NAME = 'gemini-3.1-pro-preview';

/**
 * Common helper to initialize the Gen AI client
 */
function getAiClient() {
  const apiKey = GEMINI_API_KEY.value();
  if (!apiKey) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'The function must be configured with a GEMINI_API_KEY.'
    );
  }
  return new GoogleGenerativeAI(apiKey);
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
    // 1. Verify Authentication (optional if app is meant to be offline/unauthed, 
    //    but recommended to prevent public abuse)
    // if (!request.auth) {
    //   throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
    // }

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
      const model = ai.getGenerativeModel({
        model: MODEL_NAME,
        systemInstruction: systemPrompt || 'You are a Quran memorization (Hifz) planning assistant. Generate a daily plan based on the user\'s profile and progress. Return valid JSON only.',
        generationConfig: {
          responseMimeType: 'application/json',
          temperature: 0.3,
        }
      });
      
      const response = await model.generateContent(userMessage);

      const text = response.response.text();
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
    const data = request.data;
    if (!data.context) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing "context" in request data.');
    }

    const { context, systemPrompt } = data;
    const contextJson = JSON.stringify(context, null, 2);
    const userMessage = `Generate today's memorization plan based on this user context:\n\n${contextJson}\n\nGenerate the daily plan as JSON.`;

    try {
      const ai = getAiClient();
      const model = ai.getGenerativeModel({
        model: MODEL_NAME,
        systemInstruction: systemPrompt || 'You are a Quran memorization (Hifz) coach analyzing a student\'s weekly performance.',
        generationConfig: {
          responseMimeType: 'application/json',
          temperature: 0.3,
        }
      });
      
      const response = await model.generateContent(userMessage);

      const text = response.response.text();
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
