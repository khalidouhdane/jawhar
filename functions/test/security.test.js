const assert = require('assert');
const {describe, it} = require('node:test');
const {
  hasCallableAuthentication,
  isAllowedProxyUrl,
  shouldForwardAuthHeaders,
} = require('../lib/security');

describe('Functions security helpers', () => {
  it('requires callable authentication context', () => {
    assert.equal(hasCallableAuthentication(null), false);
    assert.equal(hasCallableAuthentication(undefined), false);
    assert.equal(hasCallableAuthentication({uid: 'user'}), true);
  });

  it('allows only HTTPS Quran service targets', () => {
    assert.equal(
      isAllowedProxyUrl(
        'https://prelive-oauth2.quran.foundation/oauth2/token'
      ),
      true
    );
    assert.equal(
      isAllowedProxyUrl('https://server11.mp3quran.net/koshi/001.mp3'),
      true
    );
    assert.equal(
      isAllowedProxyUrl('http://apis.quran.foundation/content/api/v4'),
      false
    );
    assert.equal(
      isAllowedProxyUrl('https://user:pass@apis.quran.foundation/path'),
      false
    );
    assert.equal(isAllowedProxyUrl('https://example.com/path'), false);
  });

  it('rejects suffix-confusion and lookalike hosts', () => {
    assert.equal(
      isAllowedProxyUrl('https://apis.quran.foundation.evil.com/path'),
      false
    );
    assert.equal(isAllowedProxyUrl('https://evilquran.foundation/path'), false);
    assert.equal(isAllowedProxyUrl('https://evilmp3quran.net/path'), false);
    assert.equal(
      isAllowedProxyUrl('https://APIS.QURAN.FOUNDATION/content'),
      true
    );
  });

  it('only forwards auth headers to Quran Foundation hosts', () => {
    assert.equal(
      shouldForwardAuthHeaders('https://apis.quran.foundation/content'),
      true
    );
    assert.equal(
      shouldForwardAuthHeaders('https://oauth2.quran.foundation/userinfo'),
      true
    );
    assert.equal(
      shouldForwardAuthHeaders('https://server11.mp3quran.net/file.mp3'),
      false
    );
    assert.equal(
      shouldForwardAuthHeaders('https://quranenc.com/api/v1'),
      false
    );
    assert.equal(
      shouldForwardAuthHeaders('https://quran.foundation.evil.com/x'),
      false
    );
    assert.equal(shouldForwardAuthHeaders('not a url'), false);
  });
});
