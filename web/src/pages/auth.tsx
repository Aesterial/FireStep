import { ArrowRightIcon } from '@heroicons/react/24/outline';
import { AnimatePresence, motion } from 'framer-motion';
import Head from 'next/head';
import Link from 'next/link';
import { useRouter } from 'next/router';
import { type FormEvent, useState } from 'react';

import FireIcon from '../components/FireIcon';
import Spinner from '../components/Spinner';
import { useAuth } from '../contexts/AuthContext';
import {
  authService,
  type LoginRequest,
  type RegisterRequest,
} from '../contracts/auth';

type AuthMode = 'login' | 'register';

const authModes: Array<{ id: AuthMode; label: string }> = [
  { id: 'login', label: 'Вход' },
  { id: 'register', label: 'Регистрация' },
];

export default function AuthPage() {
  const [mode, setMode] = useState<AuthMode>('login');
  const [loginData, setLoginData] = useState<LoginRequest>({
    username: '',
    password: '',
  });
  const [registerData, setRegisterData] = useState<RegisterRequest>({
    username: '',
    email: '',
    password: '',
    initials: '',
    org: '',
  });
  const [pendingAction, setPendingAction] = useState<AuthMode | null>(null);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const router = useRouter();
  const { setUser } = useAuth();

  const handleLogin = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setPendingAction('login');
    setError('');
    setSuccess('');

    try {
      const response = await authService.login(loginData);
      setUser(response.user);
      setSuccess(`Сессия открыта для ${response.user.username}.`);
      await router.push(response.user.isAdmin ? '/admin' : '/stats');
    } catch (caughtError) {
      setError(
        caughtError instanceof Error
          ? caughtError.message
          : 'Не удалось выполнить вход.',
      );
    } finally {
      setPendingAction(null);
    }
  };

  const handleRegister = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setPendingAction('register');
    setError('');
    setSuccess('');

    try {
      const response = await authService.register(registerData);
      setUser(response.user);
      setSuccess(`Аккаунт ${response.user.username} создан.`);
      await router.push(response.user.isAdmin ? '/admin' : '/stats');
    } catch (caughtError) {
      setError(
        caughtError instanceof Error
          ? caughtError.message
          : 'Не удалось выполнить регистрацию.',
      );
    } finally {
      setPendingAction(null);
    }
  };

  return (
    <>
      <Head>
        <title>FireStep - вход и регистрация</title>
        <meta
          name='description'
          content='Вход и регистрация в FireStep.'
        />
        <meta name='viewport' content='width=device-width, initial-scale=1' />
      </Head>

      <div className='relative flex min-h-screen items-center justify-center px-4 py-24 sm:px-6 lg:px-8'>
        <div className='absolute inset-0 -z-10'>
          <div className='absolute left-1/2 top-24 h-72 w-72 -translate-x-1/2 rounded-full bg-orange-500/12 blur-3xl' />
        </div>

        <motion.div
          initial={{ opacity: 0, y: 18 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.3 }}
          className='glass-panel w-full max-w-md rounded-[32px] p-6 sm:p-8'
        >
          <Link href='/' className='mb-8 flex items-center justify-center gap-3'>
            <div className='rounded-2xl bg-white/70 p-2 dark:bg-white/10'>
              <FireIcon />
            </div>
            <span className='font-display text-2xl font-semibold text-stone-950 dark:text-stone-50'>
              FireStep
            </span>
          </Link>

          <div className='relative grid grid-cols-2 rounded-full border border-black/5 bg-white/55 p-1 dark:border-white/10 dark:bg-white/5'>
            {authModes.map((item) => (
              <button
                key={item.id}
                onClick={() => {
                  setMode(item.id);
                  setError('');
                  setSuccess('');
                }}
                className={`relative z-10 rounded-full px-4 py-3 text-sm font-semibold transition-colors ${
                  mode === item.id
                    ? 'text-stone-950 dark:text-stone-950'
                    : 'text-stone-500 hover:text-stone-900 dark:text-stone-400 dark:hover:text-white'
                }`}
                type='button'
              >
                {mode === item.id ? (
                  <motion.span
                    layoutId='auth-switch'
                    className='absolute inset-0 rounded-full bg-stone-950 dark:bg-stone-50'
                    transition={{ type: 'spring', stiffness: 280, damping: 26 }}
                  />
                ) : null}
                <span className='relative z-10'>{item.label}</span>
              </button>
            ))}
          </div>

          <AnimatePresence mode='wait'>
            <motion.div
              key={mode}
              initial={{ opacity: 0, y: 14 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              transition={{ duration: 0.22 }}
              className='mt-6'
            >
              {error ? (
                <div className='mb-4 rounded-[24px] border border-red-500/18 bg-red-500/10 px-4 py-3 text-sm text-red-700 dark:text-red-300'>
                  {error}
                </div>
              ) : null}

              {success ? (
                <div className='mb-4 rounded-[24px] border border-emerald-500/18 bg-emerald-500/10 px-4 py-3 text-sm text-emerald-700 dark:text-emerald-300'>
                  {success}
                </div>
              ) : null}

              {mode === 'login' ? (
                <form onSubmit={handleLogin} className='space-y-4'>
                  <div>
                    <label className='mb-2 block text-sm font-medium text-stone-600 dark:text-stone-300'>
                      Username
                    </label>
                    <input
                      type='text'
                      value={loginData.username}
                      onChange={(event) =>
                        setLoginData((previous) => ({
                          ...previous,
                          username: event.target.value,
                        }))
                      }
                      className='input-shell'
                      placeholder='firestep-user'
                      autoComplete='username'
                      required
                    />
                  </div>

                  <div>
                    <label className='mb-2 block text-sm font-medium text-stone-600 dark:text-stone-300'>
                      Пароль
                    </label>
                    <input
                      type='password'
                      value={loginData.password}
                      onChange={(event) =>
                        setLoginData((previous) => ({
                          ...previous,
                          password: event.target.value,
                        }))
                      }
                      className='input-shell'
                      placeholder='Введите пароль'
                      autoComplete='current-password'
                      required
                    />
                  </div>

                  <button
                    type='submit'
                    disabled={pendingAction === 'login'}
                    className='fire-button relative mt-2 w-full disabled:cursor-not-allowed disabled:opacity-70'
                  >
                    {pendingAction === 'login' ? (
                      <>
                        <Spinner className='absolute left-4 top-1/2 -translate-y-1/2' />
                        Загрузка
                      </>
                    ) : (
                      <>
                        Войти
                        <ArrowRightIcon className='h-4 w-4' />
                      </>
                    )}
                  </button>
                </form>
              ) : (
                <form onSubmit={handleRegister} className='space-y-4'>
                  <div>
                    <label className='mb-2 block text-sm font-medium text-stone-600 dark:text-stone-300'>
                      Username
                    </label>
                    <input
                      type='text'
                      value={registerData.username}
                      onChange={(event) =>
                        setRegisterData((previous) => ({
                          ...previous,
                          username: event.target.value,
                        }))
                      }
                      className='input-shell'
                      placeholder='firestep-user'
                      autoComplete='username'
                      required
                    />
                  </div>

                  <div>
                    <label className='mb-2 block text-sm font-medium text-stone-600 dark:text-stone-300'>
                      Email
                    </label>
                    <input
                      type='email'
                      value={registerData.email}
                      onChange={(event) =>
                        setRegisterData((previous) => ({
                          ...previous,
                          email: event.target.value,
                        }))
                      }
                      className='input-shell'
                      placeholder='you@company.com'
                      autoComplete='email'
                      required
                    />
                  </div>

                  <div>
                    <label className='mb-2 block text-sm font-medium text-stone-600 dark:text-stone-300'>
                      Инициалы
                    </label>
                    <input
                      type='text'
                      value={registerData.initials}
                      onChange={(event) =>
                        setRegisterData((previous) => ({
                          ...previous,
                          initials: event.target.value,
                        }))
                      }
                      className='input-shell'
                      placeholder='ИО'
                      required
                    />
                  </div>

                  <div>
                    <label className='mb-2 block text-sm font-medium text-stone-600 dark:text-stone-300'>
                      Организация
                    </label>
                    <input
                      type='text'
                      value={registerData.org}
                      onChange={(event) =>
                        setRegisterData((previous) => ({
                          ...previous,
                          org: event.target.value,
                        }))
                      }
                      className='input-shell'
                      placeholder='PMH Lab'
                      required
                    />
                  </div>

                  <div>
                    <label className='mb-2 block text-sm font-medium text-stone-600 dark:text-stone-300'>
                      Пароль
                    </label>
                    <input
                      type='password'
                      value={registerData.password}
                      onChange={(event) =>
                        setRegisterData((previous) => ({
                          ...previous,
                          password: event.target.value,
                        }))
                      }
                      className='input-shell'
                      placeholder='Придумайте пароль'
                      autoComplete='new-password'
                      required
                    />
                  </div>

                  <button
                    type='submit'
                    disabled={pendingAction === 'register'}
                    className='fire-button relative mt-2 w-full disabled:cursor-not-allowed disabled:opacity-70'
                  >
                    {pendingAction === 'register' ? (
                      <>
                        <Spinner className='absolute left-4 top-1/2 -translate-y-1/2' />
                        Загрузка
                      </>
                    ) : (
                      <>
                        Зарегистрироваться
                        <ArrowRightIcon className='h-4 w-4' />
                      </>
                    )}
                  </button>
                </form>
              )}
            </motion.div>
          </AnimatePresence>
        </motion.div>
      </div>
    </>
  );
}
