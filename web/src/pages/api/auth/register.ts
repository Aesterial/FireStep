import { serialize } from 'cookie';
import type { NextApiRequest, NextApiResponse } from 'next';

import type { RegisterRequest } from '../../../contracts/auth';
import {
  detectAdminBySession,
  GrpcBackendError,
  registerWithBackend,
  SESSION_COOKIE_NAME,
} from '../../../server/grpc/firestep';

interface ErrorResponse {
  message: string;
}

function isRegisterRequest(value: unknown): value is RegisterRequest {
  if (!value || typeof value !== 'object') {
    return false;
  }

  const payload = value as Record<string, unknown>;

  return (
    typeof payload.username === 'string' &&
    typeof payload.email === 'string' &&
    typeof payload.password === 'string' &&
    typeof payload.initials === 'string' &&
    typeof payload.org === 'string'
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

  if (!isRegisterRequest(request.body)) {
    response.status(400).json({
      message: 'Некорректный payload для регистрации.',
    } satisfies ErrorResponse);
    return;
  }

  try {
    const result = await registerWithBackend(request.body);

    if (!result.sessionId) {
      throw new GrpcBackendError('Backend не вернул идентификатор сессии.', 502);
    }

    const isAdmin = await detectAdminBySession(result.sessionId);

    response.setHeader(
      'Set-Cookie',
      serialize(SESSION_COOKIE_NAME, result.sessionId, {
        httpOnly: true,
        sameSite: 'lax',
        secure: process.env.NODE_ENV === 'production',
        path: '/',
      }),
    );

    response.status(200).json({
      user: {
        ...result.user,
        isAdmin,
      },
    });
  } catch (error) {
    if (error instanceof GrpcBackendError) {
      response
        .status(error.statusCode)
        .json({ message: error.message } satisfies ErrorResponse);
      return;
    }

    response.status(500).json({
      message: 'Внутренняя ошибка auth proxy.',
    } satisfies ErrorResponse);
  }
}
