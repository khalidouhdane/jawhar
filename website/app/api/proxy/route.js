export const dynamic = 'force-dynamic';

// Mirrors functions/src/security.ts — keep the two lists in sync.
const PROXY_ALLOWED_HOSTS = [
  'apis.quran.foundation',
  'prelive-apis.quran.foundation',
  'prelive-oauth2.quran.foundation',
  'oauth2.quran.foundation',
  'quranenc.com',
  'mp3quran.net',
];

function isAllowedProxyUrl(value) {
  try {
    const url = new URL(value);
    if (url.protocol !== 'https:' || url.username || url.password) {
      return false;
    }
    const hostname = url.hostname.toLowerCase();
    return PROXY_ALLOWED_HOSTS.some(
      (host) => hostname === host || hostname.endsWith(`.${host}`)
    );
  } catch {
    return false;
  }
}

// Auth headers must only reach Quran Foundation hosts — never the public
// content hosts (quranenc.com, mp3quran.net).
function shouldForwardAuthHeaders(value) {
  try {
    const hostname = new URL(value).hostname.toLowerCase();
    return (
      hostname === 'quran.foundation' ||
      hostname.endsWith('.quran.foundation')
    );
  } catch {
    return false;
  }
}

export async function OPTIONS(request) {
  return new Response(null, {
    status: 204,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization, x-auth-token, x-client-id',
      'Access-Control-Max-Age': '86400',
    },
  });
}

export async function POST(request) {
  return handleRequest(request);
}

export async function GET(request) {
  return handleRequest(request);
}

async function handleRequest(request) {
  try {
    const url = new URL(request.url);
    const targetUrl = url.searchParams.get('url');

    if (!targetUrl) {
      return new Response('Missing url parameter', { status: 400 });
    }
    if (!isAllowedProxyUrl(targetUrl)) {
      return new Response('Target URL is not allowed', {
        status: 403,
        headers: { 'Access-Control-Allow-Origin': '*' },
      });
    }

    const headers = new Headers();
    if (request.headers.get('Content-Type')) headers.set('Content-Type', request.headers.get('Content-Type'));
    if (shouldForwardAuthHeaders(targetUrl)) {
      if (request.headers.get('Authorization')) headers.set('Authorization', request.headers.get('Authorization'));
      if (request.headers.get('x-auth-token')) headers.set('x-auth-token', request.headers.get('x-auth-token'));
      if (request.headers.get('x-client-id')) headers.set('x-client-id', request.headers.get('x-client-id'));
    }

    const fetchOptions = {
      method: request.method,
      headers: headers,
    };

    if (request.method !== 'GET' && request.method !== 'HEAD') {
      fetchOptions.body = await request.arrayBuffer();
    }

    const fetchResponse = await fetch(targetUrl, fetchOptions);
    const data = await fetchResponse.arrayBuffer();

    const responseHeaders = new Headers();
    responseHeaders.set('Access-Control-Allow-Origin', '*');

    // Copy safe headers from the target response
    fetchResponse.headers.forEach((value, key) => {
      const lowerKey = key.toLowerCase();
      if (!['access-control-allow-origin', 'content-encoding', 'content-length', 'transfer-encoding'].includes(lowerKey)) {
        responseHeaders.set(key, value);
      }
    });

    return new Response(data, {
      status: fetchResponse.status,
      headers: responseHeaders,
    });
  } catch (error) {
    console.error('Proxy Error:', error);
    return new Response(`Proxy Error: ${error.message}`, {
      status: 500,
      headers: {
        'Access-Control-Allow-Origin': '*'
      }
    });
  }
}
