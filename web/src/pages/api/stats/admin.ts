import { parse as parseCookie } from 'cookie';
import type { NextApiRequest, NextApiResponse } from 'next';

import type { AdminStatsResponse } from '../../../contracts/app';
import {
  getAdminGraphBySession,
  getAdminOverviewBySession,
  getCurrentUserBySession,
  GrpcBackendError,
  listUsersBySession,
  SESSION_COOKIE_NAME,
} from '../../../server/grpc/firestep';

interface ErrorResponse {
  message: string;
}

export default async function handler(
  request: NextApiRequest,
  response: NextApiResponse<AdminStatsResponse | ErrorResponse>,
) {
  if (request.method !== 'GET') {
    response.setHeader('Allow', 'GET');
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
    const user = await getCurrentUserBySession(sessionId);

    if (!user.isAdmin) {
      response.status(403).json({ message: 'Доступно только администратору.' });
      return;
    }

    const [overview, graph, users] = await Promise.all([
      getAdminOverviewBySession(sessionId),
      getAdminGraphBySession(sessionId),
      listUsersBySession(sessionId),
    ]);

    response.status(200).json({
      user,
      overview,
      graph,
      users,
    });
  } catch (error) {
    if (error instanceof GrpcBackendError) {
      response.status(error.statusCode).json({ message: error.message });
      return;
    }

    response.status(500).json({
      message: 'Не удалось загрузить админ-статистику.',
    });
  }
}
