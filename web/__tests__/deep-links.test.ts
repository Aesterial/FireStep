import { buildClientAuthDeepLink } from '../src/lib/deep-links';

describe('buildClientAuthDeepLink', () => {
  it('builds a protocol URL with a query token', () => {
    expect(buildClientAuthDeepLink('abc-123')).toBe(
      'firestep://auth?token=abc-123',
    );
  });

  it('encodes the session token', () => {
    expect(buildClientAuthDeepLink('a+b/c==')).toBe(
      'firestep://auth?token=a%2Bb%2Fc%3D%3D',
    );
  });
});
