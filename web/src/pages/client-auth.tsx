import Head from 'next/head';
import { useRouter } from 'next/router';
import { useEffect, useState } from 'react';

import Spinner from '../components/Spinner';
import { useAuth } from '../contexts/AuthContext';

interface ClientAuthApiResponse {
  session: string;
  deepLink: string;
}

interface ErrorResponse {
  message: string;
}

export default function ClientAuthPage() {
  const router = useRouter();
  const { user, isLoading } = useAuth();
  const [pending, setPending] = useState(false);
  const [error, setError] = useState('');
  const [deepLink, setDeepLink] = useState('');
  const [sessionToken, setSessionToken] = useState('');
  const [copyState, setCopyState] = useState('');

  useEffect(() => {
    if (!isLoading && !user) {
      void router.replace('/auth');
    }
  }, [isLoading, router, user]);

  const handleAuthorize = async () => {
    setPending(true);
    setError('');
    setDeepLink('');
    setSessionToken('');
    setCopyState('');

    try {
      const response = await fetch('/api/client-auth', {
        method: 'POST',
        credentials: 'same-origin',
      });

      if (!response.ok) {
        const payload = (await response.json()) as ErrorResponse;
        throw new Error(payload.message || 'Не удалось получить client session.');
      }

      const payload = (await response.json()) as ClientAuthApiResponse;
      setDeepLink(payload.deepLink);
      setSessionToken(payload.session);
    } catch (caughtError) {
      setError(
        caughtError instanceof Error
          ? caughtError.message
          : 'Не удалось получить client session.',
      );
    } finally {
      setPending(false);
    }
  };

  const handleOpenApp = () => {
    if (!deepLink) {
      return;
    }

    window.location.assign(deepLink);
  };

  const handleCopy = async (value: string, successMessage: string) => {
    try {
      await navigator.clipboard.writeText(value);
      setCopyState(successMessage);
    } catch {
      setCopyState('Не удалось скопировать значение.');
    }
  };

  return (
    <>
      <Head>
        <title>FireStep - client auth</title>
      </Head>

      <div className='flex min-h-screen items-center justify-center px-4 py-24'>
        <div className='glass-panel w-full max-w-md rounded-[32px] p-8 text-center'>
          <h1 className='font-display text-3xl font-semibold text-stone-950 dark:text-stone-50'>
            Client Auth
          </h1>
          {error ? (
            <div className='mt-6 rounded-[24px] border border-red-500/18 bg-red-500/10 px-4 py-3 text-sm text-red-700 dark:text-red-300'>
              {error}
            </div>
          ) : null}

          {deepLink ? (
            <>
              <div className='mt-6 rounded-[24px] border border-emerald-500/18 bg-emerald-500/10 px-4 py-3 text-sm text-emerald-700 dark:text-emerald-300'>
                Токен готов. Нажмите кнопку ниже, чтобы браузер открыл FireStep и
                передал сессию приложению.
              </div>

              <button
                type='button'
                onClick={handleOpenApp}
                className='fire-button mt-8 w-full'
              >
                Открыть FireStep
              </button>

              <div className='mt-4 rounded-[24px] border border-stone-200/70 bg-stone-50/80 px-4 py-3 text-left text-sm text-stone-700 dark:border-stone-800 dark:bg-stone-950/50 dark:text-stone-300'>
                Если после нажатия ничего не происходит, в Windows, скорее всего, не
                зарегистрирован обработчик `firestep://`.
              </div>

              <button
                type='button'
                onClick={() => {
                  void handleCopy(deepLink, 'Deep link скопирован.');
                }}
                className='mt-4 w-full rounded-full border border-stone-300/70 px-5 py-3 text-sm font-medium text-stone-700 transition hover:border-stone-400 hover:text-stone-950 dark:border-stone-700 dark:text-stone-300 dark:hover:border-stone-500 dark:hover:text-stone-50'
              >
                Скопировать deep link
              </button>

              <button
                type='button'
                onClick={() => {
                  void handleCopy(sessionToken, 'Токен скопирован.');
                }}
                className='mt-4 w-full rounded-full border border-stone-300/70 px-5 py-3 text-sm font-medium text-stone-700 transition hover:border-stone-400 hover:text-stone-950 dark:border-stone-700 dark:text-stone-300 dark:hover:border-stone-500 dark:hover:text-stone-50'
              >
                Скопировать токен
              </button>

              {copyState ? (
                <div className='mt-4 rounded-[24px] border border-stone-200/70 bg-stone-50/80 px-4 py-3 text-sm text-stone-700 dark:border-stone-800 dark:bg-stone-950/50 dark:text-stone-300'>
                  {copyState}
                </div>
              ) : null}

              <button
                type='button'
                onClick={() => {
                  void handleAuthorize();
                }}
                disabled={pending || isLoading || !user}
                className='mt-4 w-full rounded-full border border-stone-300/70 px-5 py-3 text-sm font-medium text-stone-700 transition hover:border-stone-400 hover:text-stone-950 disabled:cursor-not-allowed disabled:opacity-70 dark:border-stone-700 dark:text-stone-300 dark:hover:border-stone-500 dark:hover:text-stone-50'
              >
                Получить новый токен
              </button>
            </>
          ) : (
            <button
              type='button'
              onClick={() => {
                void handleAuthorize();
              }}
              disabled={pending || isLoading || !user}
              className='fire-button relative mt-8 w-full disabled:cursor-not-allowed disabled:opacity-70'
            >
              {pending ? (
                <>
                  <Spinner className='absolute left-4 top-1/2 -translate-y-1/2' />
                  Подготавливаем вход
                </>
              ) : (
                'Подготовить вход в приложении'
              )}
            </button>
          )}
        </div>
      </div>
    </>
  );
}
