import { ArrowRightIcon, PlayCircleIcon } from '@heroicons/react/24/outline';
import { motion } from 'framer-motion';
import Link from 'next/link';

const reveal = {
  hidden: { opacity: 0, y: 26 },
  visible: (delay: number) => ({
    opacity: 1,
    y: 0,
    transition: { duration: 0.7, delay },
  }),
};

const metrics = [
  { value: '3', label: 'VR-сценария' },
  { value: '12 min', label: 'Средний проход' },
  { value: '24/7', label: 'Повторяемость обучения' },
];

export default function HeroSection() {
  return (
    <section className='ambient-grid relative overflow-hidden px-4 pb-16 pt-32 sm:px-6 lg:px-8 lg:pb-24 lg:pt-36'>
      <div className='absolute inset-0 -z-10'>
        <div className='absolute left-[8%] top-24 h-56 w-56 rounded-full bg-orange-500/18 blur-3xl animate-float' />
        <div className='absolute right-[10%] top-[18%] h-72 w-72 rounded-full bg-amber-400/12 blur-3xl animate-float-delayed' />
        <div className='absolute bottom-0 left-1/2 h-[22rem] w-[22rem] -translate-x-1/2 rounded-full bg-red-500/10 blur-3xl animate-float-slow' />
      </div>

      <div className='mx-auto grid max-w-7xl items-center gap-10 lg:grid-cols-[1.15fr_0.85fr]'>
        <div className='relative'>
          <motion.div
            custom={0.05}
            initial='hidden'
            animate='visible'
            variants={reveal}
            className='status-badge'
          >
            Тренировочная платформа
          </motion.div>

          <motion.h1
            custom={0.12}
            initial='hidden'
            animate='visible'
            variants={reveal}
            className='mt-6 max-w-4xl text-5xl font-bold leading-[0.95] tracking-tight text-stone-950 dark:text-stone-50 sm:text-6xl lg:text-8xl'
          >
            Учим
            <span className='gradient-text'> пожарной безопасности </span>
            через VR-погружение
          </motion.h1>

          <motion.p
            custom={0.2}
            initial='hidden'
            animate='visible'
            variants={reveal}
            className='mt-7 max-w-2xl text-base leading-8 text-stone-600 dark:text-stone-300 sm:text-lg'
          >
            FireStep помогает отработать действия при возгорании без риска для
            людей и оборудования: понятный маршрут, мгновенная обратная связь и
            наглядная аналитика после каждой сессии.
          </motion.p>

          <motion.div
            custom={0.28}
            initial='hidden'
            animate='visible'
            variants={reveal}
            className='mt-10 flex flex-col gap-3 sm:flex-row'
          >
            <Link href='/auth' className='fire-button'>
              Перейти к аккаунту
              <ArrowRightIcon className='h-4 w-4' />
            </Link>
            <a href='#experience' className='ghost-button'>
              Посмотреть сценарий
              <PlayCircleIcon className='h-5 w-5' />
            </a>
          </motion.div>

          <motion.div
            custom={0.36}
            initial='hidden'
            animate='visible'
            variants={reveal}
            className='mt-12 grid gap-4 sm:grid-cols-3'
          >
            {metrics.map((metric) => (
              <div
                key={metric.label}
                className='glass-panel rounded-[28px] px-5 py-4'
              >
                <div className='font-display text-2xl font-semibold text-stone-950 dark:text-stone-50'>
                  {metric.value}
                </div>
                <div className='mt-1 text-sm text-stone-500 dark:text-stone-400'>
                  {metric.label}
                </div>
              </div>
            ))}
          </motion.div>
        </div>

        <motion.div
          initial={{ opacity: 0, y: 36 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 0.24 }}
          className='relative'
        >
          <div className='glass-panel relative overflow-hidden rounded-[36px] p-4 sm:p-5'>
            <div className='absolute inset-x-10 top-0 h-28 rounded-full bg-orange-400/18 blur-3xl' />

            <div className='relative rounded-[30px] border border-white/40 bg-stone-950 p-5 text-stone-50 shadow-[0_24px_60px_rgba(15,23,42,0.36)] dark:border-white/10'>
              <div className='flex items-center justify-between'>
                <div>
                  <div className='mt-2 font-display text-2xl'>
                    Пожар в генераторной комнате
                  </div>
                </div>
              </div>

              <div className='mt-8 space-y-4'>
                {[
                  'Обнаружить перегрев и включить аварийный протокол',
                  'Выбрать корректное средство тушения',
                  'Отправить сигнал команде и завершить эвакуацию',
                ].map((item, index) => (
                  <motion.div
                    key={item}
                    initial={{ opacity: 0, x: 14 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: 0.45 + index * 0.12, duration: 0.5 }}
                    className='rounded-3xl border border-white/10 bg-white/5 p-4'
                  >
                    <div className='flex items-start gap-3'>
                      <div className='mt-1 flex h-7 w-7 items-center justify-center rounded-full bg-orange-500/18 text-sm font-semibold text-orange-200'>
                        {index + 1}
                      </div>
                      <div>
                        <div className='text-sm font-semibold text-stone-100'>
                          {item}
                        </div>
                        <div className='mt-1 text-sm text-stone-400'>
                          Система отслеживает время реакции, порядок шагов и
                          критические ошибки.
                        </div>
                      </div>
                    </div>
                  </motion.div>
                ))}
              </div>
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  );
}
