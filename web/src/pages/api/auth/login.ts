import { serialize } from 'cookie';
import type { NextApiRequest, NextApiResponse } from 'next';

import type { LoginRequest } from '../../../contracts/auth';
import {
  GrpcBackendError,
  loginWithBackend,
  SESSION_COOKIE_NAME,
} from '../../../server/grpc/auth';

interface ErrorResponse {
  message: string;
}

function isLoginRequest(value: unknown): value is LoginRequest {
  if (!value || typeof value !== 'object') {
    return false;
  }

  const payload = value as Record<string, unknown>;

  return (
    typeof payload.username === 'string' && typeof payload.password === 'string'
  );
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

  if (!isLoginRequest(request.body)) {
    response
      .status(400)
      .json({ message: 'Некорректный payload для входа.' } satisfies ErrorResponse);
    return;
  }

  try {
    const result = await loginWithBackend(request.body);

    if (!result.sessionId) {
      throw new GrpcBackendError('Backend не вернул идентификатор сессии.', 502);
    }

    response.setHeader(
      'Set-Cookie',
      serialize(SESSION_COOKIE_NAME, result.sessionId, {
        httpOnly: true,
        sameSite: 'lax',
        secure: process.env.NODE_ENV === 'production',
        path: '/',
      }),
    );

    response.status(200).json({ user: result.user });
  } catch (error) {
    if (error instanceof GrpcBackendError) {
      response
        .status(error.statusCode)
        .json({ message: error.message } satisfies ErrorResponse);
      return;
    }

    response
      .status(500)
      .json({ message: 'Внутренняя ошибка auth proxy.' } satisfies ErrorResponse);
  }
}
