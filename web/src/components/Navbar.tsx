import {Dialog} from '@headlessui/react';
import {ArrowRightIcon, Bars3Icon, MoonIcon, SunIcon, XMarkIcon,} from '@heroicons/react/24/outline';
import {AnimatePresence, motion} from 'framer-motion';
import Link from 'next/link';
import {useEffect, useState} from 'react';

import FireIcon from './FireIcon';
import {useTheme} from '../contexts/ThemeContext';

const navItems = [
  { label: 'Возможности', href: '#features' },
  { label: 'Сценарий', href: '#experience' },
  { label: 'Контакты', href: '#contacts' },
];

export default function Navbar() {
  const { theme, toggleTheme } = useTheme();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 36);

    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });

    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  return (
    <>
      <div className='fixed inset-x-0 top-4 z-50 px-4 sm:px-6 lg:px-8'>
          <motion.div
              initial={false}
              animate={{
                  maxWidth: scrolled ? 860 : 1120,
                  y: scrolled ? 0 : 6,
                  scale: scrolled ? 0.98 : 1,
              }}
              transition={{type: 'spring', stiffness: 260, damping: 26}}
              className='mx-auto w-full'
          >
          <nav
              className={`transition-all duration-300 ${
              scrolled
                ? 'glass-panel rounded-full px-4 py-2.5 shadow-[0_18px_44px_rgba(15,23,42,0.12)]'
                  : 'bg-transparent px-2 py-3'
            }`}
          >
            <div className='flex items-center justify-between gap-4'>
              <Link href='/' className='flex items-center gap-3'>
                  <motion.div
                      initial={false}
                      animate={{scale: scrolled ? 0.94 : 1}}
                      transition={{duration: 0.22}}
                      className='rounded-2xl bg-white/70 p-2 dark:bg-white/10'
                >
                  <FireIcon />
                  </motion.div>
                <span className='font-display text-lg font-semibold text-stone-950 dark:text-stone-50'>
                  FireStep
                </span>
              </Link>

                <motion.div
                    initial={false}
                    animate={{gap: scrolled ? 4 : 8}}
                    className='hidden items-center lg:flex'
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
                </motion.div>

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

                  <Link
                      href='/auth'
                      className='hidden items-center gap-2 rounded-full bg-stone-950 px-4 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-stone-800 dark:bg-stone-50 dark:text-stone-950 dark:hover:bg-white sm:inline-flex'
                  >
                      Вход
                      <ArrowRightIcon className='h-4 w-4'/>
                  </Link>

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
          </motion.div>
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
                  className='contents'
              >
                  <motion.div
                      initial={{opacity: 0, x: 24}}
                      animate={{opacity: 1, x: 0}}
                      exit={{opacity: 0, x: 16}}
                      transition={{duration: 0.22}}
                      className='glass-panel flex w-full max-w-xs flex-col rounded-[32px] p-5'
                  >
                      <div className='flex items-center justify-between'>
                          <Link
                              href='/'
                              className='flex items-center gap-3'
                              onClick={() => setMobileMenuOpen(false)}
                          >
                              <FireIcon/>
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
                              <XMarkIcon className='h-5 w-5'/>
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
                </div>

                      <div className='mt-auto pt-6'>
                          <Link
                              href='/auth'
                              onClick={() => setMobileMenuOpen(false)}
                              className='fire-button w-full'
                          >
                              Открыть аккаунт
                          </Link>
                </div>
              </Dialog.Panel>
            </div>
          </Dialog>
        ) : null}
      </AnimatePresence>
    </>
  );
}
