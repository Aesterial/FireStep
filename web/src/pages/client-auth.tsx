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

  useEffect(() => {
    if (!isLoading && !user) {
      void router.replace('/auth');
    }
  }, [isLoading, router, user]);

  const handleAuthorize = async () => {
    setPending(true);
    setError('');

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
      window.location.href = payload.deepLink;
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
                Авторизоваться
              </>
            ) : (
              'Авторизоваться'
            )}
          </button>
        </div>
      </div>
    </>
  );
}
