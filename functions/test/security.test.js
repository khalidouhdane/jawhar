const assert = require('assert');
const {describe, it} = require('node:test');
const {hasCallableAuthentication} = require('../lib/security');

describe('Functions security helpers', () => {
  it('requires callable authentication context', () => {
    assert.equal(hasCallableAuthentication(null), false);
    assert.equal(hasCallableAuthentication(undefined), false);
    assert.equal(hasCallableAuthentication({uid: 'user'}), true);
  });
});
