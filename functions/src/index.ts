import * as functions from 'firebase-functions/v2';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { defineString } from 'firebase-functions/params';
import {
  hasCallableAuthentication,
  isAllowedProxyUrl,
  shouldForwardAuthHeaders,
} from './security';

// Optional: you can switch to defineSecret if using Firebase Secret Manager
const GEMINI_API_KEY = defineString('GEMINI_API_KEY');

const MODEL_NAME = 'gemini-3.1-pro-preview';
function requireAuthentication(request: functions.https.CallableRequest) {
  if (!hasCallableAuthentication(request.auth)) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated.'
    );
  }
}

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

/**
 * CORS Proxy for Web App
 * Bypasses CORS restrictions for Quran Foundation APIs.
 */
export const quranApiProxy = functions.https.onRequest(
  {
    region: 'europe-west1',
    cors: true,
    invoker: 'public',
  },
  async (request, response) => {
    // Set CORS headers
    response.set('Access-Control-Allow-Origin', '*');
    response.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    response.set('Access-Control-Allow-Headers', 'Content-Type, Authorization, x-auth-token, x-client-id');
    response.set('Access-Control-Max-Age', '3600');

    if (request.method === 'OPTIONS') {
      response.status(204).send('');
      return;
    }

    if (request.method !== 'GET' && request.method !== 'POST') {
      response.set('Allow', 'GET, POST, OPTIONS');
      response.status(405).send('Method not allowed');
      return;
    }

    const targetUrl = request.query.url as string;
    if (!targetUrl) {
      response.status(400).send('Missing url parameter');
      return;
    }
    if (!isAllowedProxyUrl(targetUrl)) {
      response.status(403).send('Target URL is not allowed');
      return;
    }

    try {
      const headers: Record<string, string> = {};
      if (request.header('Content-Type')) headers['Content-Type'] = request.header('Content-Type')!;
      if (shouldForwardAuthHeaders(targetUrl)) {
        if (request.header('Authorization')) headers['Authorization'] = request.header('Authorization')!;
        if (request.header('x-auth-token')) headers['x-auth-token'] = request.header('x-auth-token')!;
        if (request.header('x-client-id')) headers['x-client-id'] = request.header('x-client-id')!;
      }

      const fetchOptions: RequestInit = {
        method: request.method,
        headers,
      };

      if (request.method === 'POST') {
        fetchOptions.body = request.rawBody;
      }

      const fetchResponse = await fetch(targetUrl, fetchOptions);
      const data = await fetchResponse.arrayBuffer();
      
      fetchResponse.headers.forEach((value, key) => {
        if (key.toLowerCase() !== 'access-control-allow-origin' && 
            key.toLowerCase() !== 'content-encoding' && 
            key.toLowerCase() !== 'content-length' &&
            key.toLowerCase() !== 'transfer-encoding') {
          response.set(key, value);
        }
      });

      response.status(fetchResponse.status).send(Buffer.from(data));
    } catch (error: any) {
      console.error('Proxy Error:', error);
      response.status(500).send(`Proxy Error: ${error.message}`);
    }
  }
);
