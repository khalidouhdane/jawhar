const PROXY_ALLOWED_HOSTS = [
  'apis.quran.foundation',
  'prelive-apis.quran.foundation',
  'prelive-oauth2.quran.foundation',
  'oauth2.quran.foundation',
  'quranenc.com',
  'mp3quran.net',
];

export function hasCallableAuthentication(auth: unknown): boolean {
  return auth != null;
}

export function isAllowedProxyUrl(value: string): boolean {
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

/**
 * Auth headers (Authorization, x-auth-token, x-client-id) must only be
 * forwarded to Quran Foundation hosts — never to the public content hosts
 * (quranenc.com, mp3quran.net), which have no business receiving QF tokens.
 */
export function shouldForwardAuthHeaders(value: string): boolean {
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
