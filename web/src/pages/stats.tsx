import { ClockIcon, ExclamationTriangleIcon, PlayIcon } from '@heroicons/react/24/outline';
import Head from 'next/head';
import Link from 'next/link';
import { useRouter } from 'next/router';
import { useEffect, useState } from 'react';

import Navbar from '../components/Navbar';
import Spinner from '../components/Spinner';
import { useAuth } from '../contexts/AuthContext';
import type { UserStatsResponse } from '../contracts/app';

interface ErrorResponse {
  message: string;
}

function formatDate(value: string) {
  if (!value) {
    return '—';
  }

  return new Intl.DateTimeFormat('ru-RU', {
    day: '2-digit',
    month: 'short',
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(value));
}

export default function StatsPage() {
  const router = useRouter();
  const { user, isLoading } = useAuth();
  const [data, setData] = useState<UserStatsResponse | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!isLoading && !user) {
      void router.replace('/auth');
    }
  }, [isLoading, router, user]);

  useEffect(() => {
    if (!user) {
      return;
    }

    const load = async () => {
      setLoading(true);
      setError('');

      try {
        const response = await fetch('/api/stats/user', {
          credentials: 'same-origin',
        });

        if (!response.ok) {
          const payload = (await response.json()) as ErrorResponse;
          throw new Error(payload.message || 'Не удалось загрузить статистику.');
        }

        setData((await response.json()) as UserStatsResponse);
      } catch (caughtError) {
        setError(
          caughtError instanceof Error
            ? caughtError.message
            : 'Не удалось загрузить статистику.',
        );
      } finally {
        setLoading(false);
      }
    };

    void load();
  }, [user]);

  return (
    <>
      <Head>
        <title>FireStep - моя статистика</title>
      </Head>

      <div className='min-h-screen px-4 pb-12 pt-28 sm:px-6 lg:px-8'>
        <Navbar />

        <div className='mx-auto max-w-6xl space-y-6'>
          <div>
            <div className='status-badge'>Пользователь</div>
            <h1 className='mt-4 text-4xl font-semibold text-stone-950 dark:text-stone-50'>
              Моя статистика
            </h1>
            <p className='mt-3 max-w-2xl text-sm leading-7 text-stone-600 dark:text-stone-300'>
              История прохождений, ошибки, среднее время реакции и активные
              веб-сессии текущего пользователя.
            </p>
          </div>

          {loading ? (
            <div className='glass-panel flex min-h-[280px] items-center justify-center rounded-[32px]'>
              <div className='flex items-center gap-3 text-sm text-stone-500 dark:text-stone-400'>
                <Spinner />
                Загрузка статистики
              </div>
            </div>
          ) : null}

          {!loading && error ? (
            <div className='glass-panel rounded-[32px] p-6 text-sm text-red-600 dark:text-red-300'>
              {error}
            </div>
          ) : null}

          {!loading && data ? (
            <>
              <div className='grid gap-4 md:grid-cols-4'>
                {[
                  {
                    label: 'Прохождений',
                    value: data.summary.seancesCount,
                    icon: PlayIcon,
                  },
                  {
                    label: 'Ошибок',
                    value: data.summary.totalErrors,
                    icon: ExclamationTriangleIcon,
                  },
                  {
                    label: 'Среднее время',
                    value: `${data.summary.avgSeconds} сек`,
                    icon: ClockIcon,
                  },
                  {
                    label: 'Лучший результат',
                    value: `${data.summary.bestSeconds} сек`,
                    icon: ClockIcon,
                  },
                ].map((item) => {
                  const Icon = item.icon;

                  return (
                    <div
                      key={item.label}
                      className='glass-panel rounded-[28px] p-5'
                    >
                      <Icon className='h-5 w-5 text-orange-500' />
                      <div className='mt-4 font-display text-3xl font-semibold text-stone-950 dark:text-stone-50'>
                        {item.value}
                      </div>
                      <div className='mt-2 text-sm text-stone-500 dark:text-stone-400'>
                        {item.label}
                      </div>
                    </div>
                  );
                })}
              </div>

              <div className='grid gap-6 lg:grid-cols-[1.15fr_0.85fr]'>
                <div className='glass-panel rounded-[32px] p-6'>
                  <div className='flex items-center justify-between gap-3'>
                    <h2 className='text-2xl font-semibold text-stone-950 dark:text-stone-50'>
                      Последние игровые сессии
                    </h2>
                    <div className='text-xs uppercase tracking-[0.2em] text-stone-500 dark:text-stone-400'>
                      {data.seances.length} записей
                    </div>
                  </div>

                  <div className='mt-6 space-y-3'>
                    {data.seances.length > 0 ? (
                      data.seances.slice(0, 8).map((seance) => (
                        <div
                          key={seance.id}
                          className='rounded-[24px] border border-black/5 bg-white/50 p-4 dark:border-white/10 dark:bg-white/5'
                        >
                          <div className='flex items-center justify-between gap-4'>
                            <div>
                              <div className='text-sm font-semibold text-stone-900 dark:text-stone-100'>
                                Сессия {seance.id.slice(0, 8)}
                              </div>
                              <div className='mt-1 text-sm text-stone-500 dark:text-stone-400'>
                                {formatDate(seance.doneAt)}
                              </div>
                            </div>
                            <div className='text-right text-sm text-stone-600 dark:text-stone-300'>
                              <div>{seance.durationSeconds} сек</div>
                              <div>{seance.errors} ошибок</div>
                            </div>
                          </div>
                          <div className='mt-3 text-xs uppercase tracking-[0.2em] text-stone-400 dark:text-stone-500'>
                            {seance.actionsCount} действий
                          </div>
                        </div>
                      ))
                    ) : (
                      <div className='rounded-[24px] border border-dashed border-black/10 p-5 text-sm text-stone-500 dark:border-white/10 dark:text-stone-400'>
                        У пользователя пока нет сохранённых игровых сессий.
                      </div>
                    )}
                  </div>
                </div>

                <div className='space-y-6'>
                  <div className='glass-panel rounded-[32px] p-6'>
                    <h2 className='text-2xl font-semibold text-stone-950 dark:text-stone-50'>
                      Профиль
                    </h2>
                    <div className='mt-5 space-y-3 text-sm text-stone-600 dark:text-stone-300'>
                      <div>Логин: {data.user.username}</div>
                      <div>Email: {data.user.email}</div>
                      <div>Организация: {data.user.org || '—'}</div>
                      <div>Последняя игра: {formatDate(data.summary.lastPlayedAt)}</div>
                    </div>
                  </div>

                  <div className='glass-panel rounded-[32px] p-6'>
                    <h2 className='text-2xl font-semibold text-stone-950 dark:text-stone-50'>
                      Активные входы
                    </h2>
                    <div className='mt-5 space-y-3'>
                      {data.sessions.map((session) => (
                        <div
                          key={session.id}
                          className='rounded-[22px] border border-black/5 bg-white/50 p-4 text-sm text-stone-600 dark:border-white/10 dark:bg-white/5 dark:text-stone-300'
                        >
                          <div className='font-semibold text-stone-900 dark:text-stone-100'>
                            {session.device || 'web'}
                          </div>
                          <div className='mt-1'>
                            Последняя активность: {formatDate(session.lastSeenAt)}
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>

                  {data.user.isAdmin ? (
                    <Link href='/admin' className='fire-button w-full'>
                      Перейти в админ панель
                    </Link>
                  ) : null}
                </div>
              </div>
            </>
          ) : null}
        </div>
      </div>
    </>
  );
}
