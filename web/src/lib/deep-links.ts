export function buildClientAuthDeepLink(session: string): string {
  return `firestep://auth?token=${encodeURIComponent(session)}`;
}
