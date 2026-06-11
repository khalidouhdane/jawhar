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

// SSRF guard (defense in depth alongside the host allow-list): never forward
// to localhost, loopback, RFC 1918 private, link-local, or IPv6 local targets.
// WHATWG URL normalizes IPv4 forms (decimal/octal/hex) to dotted-quad, so a
// literal hostname check is sufficient here. Mirrors the Windows audio-proxy
// hardening in lib/services/audio_proxy_server.dart (commit 8fb6508).
function isPrivateOrLoopbackHost(hostname) {
  const host = hostname.replace(/^\[|\]$/g, ''); // strip IPv6 brackets
  if (host === 'localhost' || host.endsWith('.localhost')) return true;
  const v4 = host.match(/^(\d{1,3})\.(\d{1,3})\.\d{1,3}\.\d{1,3}$/);
  if (v4) {
    const a = Number(v4[1]);
    const b = Number(v4[2]);
    if (a === 0 || a === 10 || a === 127) return true; // 0/8, 10/8, 127/8
    if (a === 172 && b >= 16 && b <= 31) return true; // 172.16.0.0/12
    if (a === 192 && b === 168) return true; // 192.168.0.0/16
    if (a === 169 && b === 254) return true; // 169.254.0.0/16 (link-local)
    if (a === 100 && b >= 64 && b <= 127) return true; // 100.64.0.0/10 (CGNAT)
    return false;
  }
  if (host.includes(':')) {
    // IPv6: loopback ::1, unspecified ::, unique-local fc00::/7,
    // link-local fe80::/10, and IPv4-mapped forms of any of the above.
    if (host === '::1' || host === '::') return true;
    if (/^f[cd]/.test(host)) return true; // fc00::/7
    if (/^fe[89ab]/.test(host)) return true; // fe80::/10
    if (host.startsWith('::ffff:')) {
      // WHATWG URL serializes mapped addresses in hex (::ffff:7f00:1);
      // dotted form is handled too for safety.
      const tail = host.slice('::ffff:'.length);
      if (tail.includes('.')) return isPrivateOrLoopbackHost(tail);
      const groups = tail.split(':');
      if (groups.length === 2) {
        const hi = parseInt(groups[0], 16);
        const lo = parseInt(groups[1], 16);
        return isPrivateOrLoopbackHost(
          `${hi >> 8}.${hi & 255}.${lo >> 8}.${lo & 255}`
        );
      }
    }
  }
  return false;
}

function isAllowedProxyUrl(value) {
  try {
    const url = new URL(value);
    if (url.protocol !== 'https:' || url.username || url.password) {
      return false;
    }
    const hostname = url.hostname.toLowerCase();
    if (isPrivateOrLoopbackHost(hostname)) {
      return false;
    }
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
