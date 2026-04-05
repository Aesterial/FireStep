import Link from 'next/link';

import FireIcon from './FireIcon';

export default function Footer() {
  return (
    <footer
      id='contacts'
      className='px-4 pb-10 pt-6 sm:px-6 lg:px-8'
    >
      <div className='glass-panel mx-auto max-w-6xl rounded-[32px] px-6 py-8'>
        <div className='flex flex-col gap-6 sm:flex-row sm:items-center sm:justify-between'>
          <Link href='/' className='flex items-center gap-3'>
            <div className='rounded-2xl bg-white/70 p-2 dark:bg-white/10'>
              <FireIcon />
            </div>
            <span className='font-display text-lg font-semibold text-stone-950 dark:text-stone-50'>
              FireStep
            </span>
          </Link>

          <div className='text-sm text-stone-500 dark:text-stone-400'>
            2026 Aesterial. Все права защищены.
          </div>
        </div>
      </div>
    </footer>
  );
}
