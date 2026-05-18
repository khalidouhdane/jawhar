export const dynamic = 'force-dynamic';

export async function OPTIONS(request) {
  return new Response(null, {
    status: 204,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
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

    const headers = new Headers();
    if (request.headers.get('Content-Type')) headers.set('Content-Type', request.headers.get('Content-Type'));
    if (request.headers.get('Authorization')) headers.set('Authorization', request.headers.get('Authorization'));
    if (request.headers.get('x-auth-token')) headers.set('x-auth-token', request.headers.get('x-auth-token'));
    if (request.headers.get('x-client-id')) headers.set('x-client-id', request.headers.get('x-client-id'));

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
