import { Dialog, Menu, Transition } from '@headlessui/react';
import {
  ArrowRightIcon,
  Bars3Icon,
  ChartBarIcon,
  ChevronDownIcon,
  MoonIcon,
  ShieldCheckIcon,
  SunIcon,
  XMarkIcon,
} from '@heroicons/react/24/outline';
import { AnimatePresence, motion } from 'framer-motion';
import Link from 'next/link';
import { useRouter } from 'next/router';
import { Fragment, useEffect, useState } from 'react';

import FireIcon from './FireIcon';
import { useAuth } from '../contexts/AuthContext';
import { useTheme } from '../contexts/ThemeContext';

const navItems = [
  { label: 'Возможности', href: '#features' },
  { label: 'Сценарий', href: '#experience' },
  { label: 'Контакты', href: '#contacts' },
];

export default function Navbar() {
  const router = useRouter();
  const { theme, toggleTheme } = useTheme();
  const { user, isLoading, logout } = useAuth();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 36);

    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });

    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  const statsHref = user?.isAdmin ? '/admin' : '/stats';

  const handleLogout = async () => {
    await logout();
    setMobileMenuOpen(false);
    await router.push('/');
  };

  return (
    <>
      <div className='fixed inset-x-0 top-4 z-50 px-4 sm:px-6 lg:px-8'>
        <div className='mx-auto w-full max-w-6xl'>
          <nav
            className={`dynamic-island transition-all duration-300 ease-out ${
              scrolled
                ? 'glass-panel rounded-full px-4 py-2.5 shadow-[0_18px_44px_rgba(15,23,42,0.12)]'
                : 'rounded-[24px] bg-transparent px-2 py-3'
            }`}
          >
            <div className='flex items-center justify-between gap-4'>
              <Link href='/' className='flex items-center gap-3'>
                <div
                  className={`rounded-2xl bg-white/70 p-2 transition-transform duration-300 dark:bg-white/10 ${
                    scrolled ? 'scale-[0.94]' : 'scale-100'
                  }`}
                >
                  <FireIcon />
                </div>
                <span className='font-display text-lg font-semibold text-stone-950 dark:text-stone-50'>
                  FireStep
                </span>
              </Link>

              <div
                className={`hidden items-center transition-all duration-300 lg:flex ${
                  scrolled ? 'gap-1' : 'gap-2'
                }`}
              >
                {navItems.map((item) => (
                  <a
                    key={item.href}
                    href={item.href}
                    className='rounded-full px-4 py-2 text-sm font-semibold text-stone-600 transition-colors hover:text-stone-950 dark:text-stone-300 dark:hover:text-white'
                  >
                    {item.label}
                  </a>
                ))}
              </div>

              <div className='flex items-center gap-2'>
                <button
                  onClick={toggleTheme}
                  className='rounded-full border border-black/5 bg-white/70 p-2.5 text-stone-700 transition-colors hover:bg-white dark:border-white/10 dark:bg-white/5 dark:text-stone-200 dark:hover:bg-white/10'
                  aria-label='Сменить тему'
                  type='button'
                >
                  {theme === 'dark' ? (
                    <SunIcon className='h-5 w-5' />
                  ) : (
                    <MoonIcon className='h-5 w-5' />
                  )}
                </button>

                {!isLoading && user ? (
                  <>
                    <Link
                      href={statsHref}
                      className='hidden items-center gap-2 rounded-full border border-black/5 bg-white/70 px-4 py-2.5 text-sm font-semibold text-stone-800 transition-colors hover:bg-white dark:border-white/10 dark:bg-white/5 dark:text-stone-100 dark:hover:bg-white/10 sm:inline-flex'
                    >
                      <ChartBarIcon className='h-4 w-4' />
                      {user.isAdmin ? 'Админ статистика' : 'Статистика'}
                    </Link>

                    <div className='hidden sm:block'>
                      <Menu as='div' className='relative'>
                        <Menu.Button className='inline-flex items-center gap-2 rounded-full bg-stone-950 px-4 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-stone-800 dark:bg-stone-50 dark:text-stone-950 dark:hover:bg-white'>
                          <span>{`Аккаунт · ${user.username}`}</span>
                          <ChevronDownIcon className='h-4 w-4' />
                        </Menu.Button>

                        <Transition
                          as={Fragment}
                          enter='transition duration-150 ease-out'
                          enterFrom='transform opacity-0 scale-95'
                          enterTo='transform opacity-100 scale-100'
                          leave='transition duration-100 ease-in'
                          leaveFrom='transform opacity-100 scale-100'
                          leaveTo='transform opacity-0 scale-95'
                        >
                          <Menu.Items className='glass-panel absolute right-0 mt-3 w-64 rounded-[24px] p-2 outline-none'>
                            <div className='rounded-[18px] px-3 py-2'>
                              <div className='text-sm font-semibold text-stone-950 dark:text-stone-50'>
                                {user.username}
                              </div>
                              <div className='text-xs text-stone-500 dark:text-stone-400'>
                                {user.email}
                              </div>
                            </div>

                            <Menu.Item>
                              {({ active }) => (
                                <Link
                                  href='/stats'
                                  className={`flex items-center gap-2 rounded-[18px] px-3 py-2 text-sm font-medium ${
                                    active
                                      ? 'bg-black/5 text-stone-950 dark:bg-white/5 dark:text-white'
                                      : 'text-stone-700 dark:text-stone-200'
                                  }`}
                                >
                                  <ChartBarIcon className='h-4 w-4' />
                                  Моя статистика
                                </Link>
                              )}
                            </Menu.Item>

                            {user.isAdmin ? (
                              <Menu.Item>
                                {({ active }) => (
                                  <Link
                                    href='/admin'
                                    className={`flex items-center gap-2 rounded-[18px] px-3 py-2 text-sm font-medium ${
                                      active
                                        ? 'bg-black/5 text-stone-950 dark:bg-white/5 dark:text-white'
                                        : 'text-stone-700 dark:text-stone-200'
                                    }`}
                                  >
                                    <ShieldCheckIcon className='h-4 w-4' />
                                    Админ панель
                                  </Link>
                                )}
                              </Menu.Item>
                            ) : null}

                            <Menu.Item>
                              {({ active }) => (
                                <button
                                  type='button'
                                  onClick={() => {
                                    void handleLogout();
                                  }}
                                  className={`flex w-full items-center rounded-[18px] px-3 py-2 text-left text-sm font-medium ${
                                    active
                                      ? 'bg-black/5 text-stone-950 dark:bg-white/5 dark:text-white'
                                      : 'text-stone-700 dark:text-stone-200'
                                  }`}
                                >
                                  Выйти
                                </button>
                              )}
                            </Menu.Item>
                          </Menu.Items>
                        </Transition>
                      </Menu>
                    </div>
                  </>
                ) : (
                  <Link
                    href='/auth'
                    className='hidden items-center gap-2 rounded-full bg-stone-950 px-4 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-stone-800 dark:bg-stone-50 dark:text-stone-950 dark:hover:bg-white sm:inline-flex'
                  >
                    Вход
                    <ArrowRightIcon className='h-4 w-4' />
                  </Link>
                )}

                <button
                  onClick={() => setMobileMenuOpen(true)}
                  className='rounded-full border border-black/5 bg-white/70 p-2.5 text-stone-700 dark:border-white/10 dark:bg-white/5 dark:text-stone-200 lg:hidden'
                  type='button'
                  aria-label='Открыть меню'
                >
                  <Bars3Icon className='h-5 w-5' />
                </button>
              </div>
            </div>
          </nav>
        </div>
      </div>

      <AnimatePresence>
        {mobileMenuOpen ? (
          <Dialog
            as='div'
            className='relative z-[60] lg:hidden'
            open={mobileMenuOpen}
            onClose={setMobileMenuOpen}
          >
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className='fixed inset-0 bg-black/30 backdrop-blur-md'
            />

            <div className='fixed inset-0 flex justify-end p-3'>
              <Dialog.Panel
                as={motion.div}
                initial={{ opacity: 0, x: 24 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: 16 }}
                transition={{ duration: 0.22 }}
                className='glass-panel flex w-full max-w-xs flex-col rounded-[32px] p-5'
              >
                <div className='flex items-center justify-between'>
                  <Link
                    href='/'
                    className='flex items-center gap-3'
                    onClick={() => setMobileMenuOpen(false)}
                  >
                    <FireIcon />
                    <span className='font-display text-lg font-semibold text-stone-950 dark:text-white'>
                      FireStep
                    </span>
                  </Link>

                  <button
                    onClick={() => setMobileMenuOpen(false)}
                    className='rounded-full p-2 text-stone-600 dark:text-stone-300'
                    type='button'
                    aria-label='Закрыть меню'
                  >
                    <XMarkIcon className='h-5 w-5' />
                  </button>
                </div>

                <div className='mt-8 space-y-2'>
                  {navItems.map((item) => (
                    <a
                      key={item.href}
                      href={item.href}
                      onClick={() => setMobileMenuOpen(false)}
                      className='block rounded-2xl px-4 py-3 text-base font-semibold text-stone-900 transition-colors hover:bg-black/5 dark:text-white dark:hover:bg-white/5'
                    >
                      {item.label}
                    </a>
                  ))}

                  {user ? (
                    <>
                      <Link
                        href={statsHref}
                        onClick={() => setMobileMenuOpen(false)}
                        className='block rounded-2xl px-4 py-3 text-base font-semibold text-stone-900 transition-colors hover:bg-black/5 dark:text-white dark:hover:bg-white/5'
                      >
                        {user.isAdmin ? 'Админ статистика' : 'Статистика'}
                      </Link>
                      <Link
                        href='/stats'
                        onClick={() => setMobileMenuOpen(false)}
                        className='block rounded-2xl px-4 py-3 text-base font-semibold text-stone-900 transition-colors hover:bg-black/5 dark:text-white dark:hover:bg-white/5'
                      >
                        Моя статистика
                      </Link>
                      {user.isAdmin ? (
                        <Link
                          href='/admin'
                          onClick={() => setMobileMenuOpen(false)}
                          className='block rounded-2xl px-4 py-3 text-base font-semibold text-stone-900 transition-colors hover:bg-black/5 dark:text-white dark:hover:bg-white/5'
                        >
                          Админ панель
                        </Link>
                      ) : null}
                      <button
                        type='button'
                        onClick={() => {
                          void handleLogout();
                        }}
                        className='block w-full rounded-2xl px-4 py-3 text-left text-base font-semibold text-stone-900 transition-colors hover:bg-black/5 dark:text-white dark:hover:bg-white/5'
                      >
                        Выйти
                      </button>
                    </>
                  ) : (
                    <Link
                      href='/auth'
                      onClick={() => setMobileMenuOpen(false)}
                      className='block rounded-2xl px-4 py-3 text-base font-semibold text-stone-900 transition-colors hover:bg-black/5 dark:text-white dark:hover:bg-white/5'
                    >
                      Вход
                    </Link>
                  )}
                </div>
              </Dialog.Panel>
            </div>
          </Dialog>
        ) : null}
      </AnimatePresence>
    </>
  );
}
