import { parse as parseCookie, serialize } from 'cookie';
import type { NextApiRequest, NextApiResponse } from 'next';

import {
  GrpcBackendError,
  logoutWithBackend,
  SESSION_COOKIE_NAME,
} from '../../../server/grpc/auth';

interface ErrorResponse {
  message: string;
}

export default async function handler(
  request: NextApiRequest,
  response: NextApiResponse,
) {
  if (request.method !== 'POST') {
    response.setHeader('Allow', 'POST');
    response
      .status(405)
      .json({ message: 'Method not allowed' } satisfies ErrorResponse);
    return;
  }

  const cookies = parseCookie(request.headers.cookie ?? '');
  const sessionId = cookies[SESSION_COOKIE_NAME];

  try {
    if (sessionId) {
      await logoutWithBackend(sessionId);
    }

    response.setHeader(
      'Set-Cookie',
      serialize(SESSION_COOKIE_NAME, '', {
        httpOnly: true,
        sameSite: 'lax',
        secure: process.env.NODE_ENV === 'production',
        path: '/',
        maxAge: 0,
      }),
    );

    response.status(200).json({ success: true });
  } catch (error) {
    if (error instanceof GrpcBackendError) {
      response
        .status(error.statusCode)
        .json({ message: error.message } satisfies ErrorResponse);
      return;
    }

    response
      .status(500)
      .json({ message: 'Не удалось завершить сессию.' } satisfies ErrorResponse);
  }
}
