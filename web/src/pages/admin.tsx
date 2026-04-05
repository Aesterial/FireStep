import { ChartBarIcon, ShieldCheckIcon, UsersIcon } from '@heroicons/react/24/outline';
import Head from 'next/head';
import Link from 'next/link';
import { useRouter } from 'next/router';
import { useEffect, useState } from 'react';

import Navbar from '../components/Navbar';
import Spinner from '../components/Spinner';
import { useAuth } from '../contexts/AuthContext';
import type { AdminStatsResponse } from '../contracts/app';

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

export default function AdminPage() {
  const router = useRouter();
  const { user, isLoading } = useAuth();
  const [data, setData] = useState<AdminStatsResponse | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!isLoading && !user) {
      void router.replace('/auth');
    }

    if (!isLoading && user && !user.isAdmin) {
      void router.replace('/stats');
    }
  }, [isLoading, router, user]);

  useEffect(() => {
    if (!user?.isAdmin) {
      return;
    }

    const load = async () => {
      setLoading(true);
      setError('');

      try {
        const response = await fetch('/api/stats/admin', {
          credentials: 'same-origin',
        });

        if (!response.ok) {
          const payload = (await response.json()) as ErrorResponse;
          throw new Error(payload.message || 'Не удалось загрузить админ-панель.');
        }

        setData((await response.json()) as AdminStatsResponse);
      } catch (caughtError) {
        setError(
          caughtError instanceof Error
            ? caughtError.message
            : 'Не удалось загрузить админ-панель.',
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
        <title>FireStep - админ панель</title>
      </Head>

      <div className='min-h-screen px-4 pb-12 pt-28 sm:px-6 lg:px-8'>
        <Navbar />

        <div className='mx-auto max-w-6xl space-y-6'>
          <div className='flex flex-col gap-3 lg:flex-row lg:items-end lg:justify-between'>
            <div>
              <div className='status-badge'>Admin</div>
              <h1 className='mt-4 text-4xl font-semibold text-stone-950 dark:text-stone-50'>
                Админ панель и общая статистика
              </h1>
              <p className='mt-3 max-w-2xl text-sm leading-7 text-stone-600 dark:text-stone-300'>
                Данные по организации: общие игровые сессии, ошибки, активность
                пользователей и список участников.
              </p>
            </div>

            <Link href='/stats' className='ghost-button'>
              Моя статистика
            </Link>
          </div>

          {loading ? (
            <div className='glass-panel flex min-h-[280px] items-center justify-center rounded-[32px]'>
              <div className='flex items-center gap-3 text-sm text-stone-500 dark:text-stone-400'>
                <Spinner />
                Загрузка админ-панели
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
                    label: 'Всего прохождений',
                    value: data.overview.seanceCount,
                    icon: ChartBarIcon,
                  },
                  {
                    label: 'Всего ошибок',
                    value: data.overview.errorsCount,
                    icon: ShieldCheckIcon,
                  },
                  {
                    label: 'Среднее время',
                    value: `${data.overview.avgSeconds} сек`,
                    icon: ChartBarIcon,
                  },
                  {
                    label: 'Пользователей',
                    value: data.users.length,
                    icon: UsersIcon,
                  },
                ].map((item) => {
                  const Icon = item.icon;

                  return (
                    <div key={item.label} className='glass-panel rounded-[28px] p-5'>
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

              <div className='grid gap-6 lg:grid-cols-[1fr_1fr]'>
                <div className='glass-panel rounded-[32px] p-6'>
                  <h2 className='text-2xl font-semibold text-stone-950 dark:text-stone-50'>
                    Последние прохождения
                  </h2>
                  <div className='mt-6 space-y-3'>
                    {data.overview.latest.map((seance) => (
                      <div
                        key={seance.id}
                        className='rounded-[24px] border border-black/5 bg-white/50 p-4 dark:border-white/10 dark:bg-white/5'
                      >
                        <div className='flex items-center justify-between gap-4'>
                          <div>
                            <div className='text-sm font-semibold text-stone-900 dark:text-stone-100'>
                              Пользователь {seance.ownerId.slice(0, 8)}
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
                      </div>
                    ))}
                  </div>
                </div>

                <div className='glass-panel rounded-[32px] p-6'>
                  <h2 className='text-2xl font-semibold text-stone-950 dark:text-stone-50'>
                    Графики backend
                  </h2>
                  <div className='mt-6 grid gap-4 sm:grid-cols-2'>
                    <div className='rounded-[24px] border border-black/5 bg-white/50 p-4 dark:border-white/10 dark:bg-white/5'>
                      <div className='text-sm font-semibold text-stone-900 dark:text-stone-100'>
                        Ошибки по периодам
                      </div>
                      <div className='mt-4 space-y-2 text-sm text-stone-600 dark:text-stone-300'>
                        {data.graph.errors.slice(-6).map((point) => (
                          <div key={`${point.at}-${point.count}`} className='flex items-center justify-between'>
                            <span>{formatDate(point.at)}</span>
                            <span>{point.count}</span>
                          </div>
                        ))}
                      </div>
                    </div>

                    <div className='rounded-[24px] border border-black/5 bg-white/50 p-4 dark:border-white/10 dark:bg-white/5'>
                      <div className='text-sm font-semibold text-stone-900 dark:text-stone-100'>
                        Активность пользователей
                      </div>
                      <div className='mt-4 space-y-2 text-sm text-stone-600 dark:text-stone-300'>
                        {data.graph.usersActivity.slice(-6).map((point) => (
                          <div key={`${point.at}-${point.count}`} className='flex items-center justify-between'>
                            <span>{formatDate(point.at)}</span>
                            <span>{point.count}</span>
                          </div>
                        ))}
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <div className='glass-panel rounded-[32px] p-6'>
                <div className='flex items-center justify-between gap-4'>
                  <h2 className='text-2xl font-semibold text-stone-950 dark:text-stone-50'>
                    Пользователи организации
                  </h2>
                  <div className='text-xs uppercase tracking-[0.2em] text-stone-500 dark:text-stone-400'>
                    {data.users.length} человек
                  </div>
                </div>

                <div className='mt-6 grid gap-3'>
                  {data.users.map((orgUser) => (
                    <div
                      key={orgUser.id}
                      className='grid gap-3 rounded-[24px] border border-black/5 bg-white/50 p-4 text-sm text-stone-600 dark:border-white/10 dark:bg-white/5 dark:text-stone-300 md:grid-cols-[1fr_1fr_auto]'
                    >
                      <div>
                        <div className='font-semibold text-stone-900 dark:text-stone-100'>
                          {orgUser.username}
                        </div>
                        <div className='mt-1'>{orgUser.email}</div>
                      </div>
                      <div>{orgUser.org || '—'}</div>
                      <div>С нами с {formatDate(orgUser.joined)}</div>
                    </div>
                  ))}
                </div>
              </div>
            </>
          ) : null}
        </div>
      </div>
    </>
  );
}
