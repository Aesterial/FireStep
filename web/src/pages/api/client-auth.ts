import { parse as parseCookie } from 'cookie';
import type { NextApiRequest, NextApiResponse } from 'next';

import {
  createClientSessionBySession,
  GrpcBackendError,
  SESSION_COOKIE_NAME,
} from '../../server/grpc/firestep';
import { buildClientAuthDeepLink } from '../../lib/deep-links';

interface ClientAuthResponse {
  session: string;
  deepLink: string;
}

interface ErrorResponse {
  message: string;
}

export default async function handler(
  request: NextApiRequest,
  response: NextApiResponse<ClientAuthResponse | ErrorResponse>,
) {
  if (request.method !== 'POST') {
    response.setHeader('Allow', 'POST');
    response.status(405).json({ message: 'Method not allowed' });
    return;
  }

  const cookies = parseCookie(request.headers.cookie ?? '');
  const sessionId = cookies[SESSION_COOKIE_NAME];

  if (!sessionId) {
    response.status(401).json({ message: 'Требуется авторизация.' });
    return;
  }

  try {
    const clientSession = await createClientSessionBySession(sessionId);

    if (!clientSession) {
      response
        .status(502)
        .json({ message: 'Backend не вернул client session.' });
      return;
    }

    response.status(200).json({
      session: clientSession,
      deepLink: buildClientAuthDeepLink(clientSession),
    });
  } catch (error) {
    if (error instanceof GrpcBackendError) {
      response.status(error.statusCode).json({ message: error.message });
      return;
    }

    response
      .status(500)
      .json({ message: 'Не удалось создать client session.' });
  }
}
