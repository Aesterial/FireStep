import { parse as parseCookie } from 'cookie';
import type { NextApiRequest, NextApiResponse } from 'next';

import type { UserStatsResponse } from '../../../contracts/app';
import {
  getCurrentUserBySession,
  GrpcBackendError,
  listSeancesBySession,
  listSessionsBySession,
  SESSION_COOKIE_NAME,
} from '../../../server/grpc/firestep';

interface ErrorResponse {
  message: string;
}

export default async function handler(
  request: NextApiRequest,
  response: NextApiResponse<UserStatsResponse | ErrorResponse>,
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
    const [user, seances, sessions] = await Promise.all([
      getCurrentUserBySession(sessionId),
      listSeancesBySession(sessionId),
      listSessionsBySession(sessionId),
    ]);

    const totalDuration = seances.reduce(
      (sum, seance) => sum + seance.durationSeconds,
      0,
    );
    const totalErrors = seances.reduce((sum, seance) => sum + seance.errors, 0);
    const bestSeconds =
      seances.length > 0
        ? Math.min(...seances.map((seance) => seance.durationSeconds || Infinity))
        : 0;

    response.status(200).json({
      user,
      summary: {
        seancesCount: seances.length,
        totalErrors,
        avgSeconds:
          seances.length > 0 ? Math.round(totalDuration / seances.length) : 0,
        bestSeconds: Number.isFinite(bestSeconds) ? bestSeconds : 0,
        lastPlayedAt: seances[0]?.doneAt ?? '',
      },
      seances,
      sessions,
    });
  } catch (error) {
    if (error instanceof GrpcBackendError) {
      response.status(error.statusCode).json({ message: error.message });
      return;
    }

    response.status(500).json({
      message: 'Не удалось загрузить пользовательскую статистику.',
    });
  }
}
