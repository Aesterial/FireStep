import {
  BoltIcon,
  ChatBubbleLeftRightIcon,
  CubeTransparentIcon,
  ShieldCheckIcon,
} from '@heroicons/react/24/outline';
import { motion } from 'framer-motion';

const features = [
  {
    title: 'Детализированная VR-среда',
    description:
      'Цех, оборудование и опасные зоны выглядят как реальный объект, поэтому поведение переносится в практику без адаптационного провала.',
    icon: CubeTransparentIcon,
  },
  {
    title: 'Сценарии с развилками',
    description:
      'Каждое действие влияет на развитие инцидента: можно потерять время, выбрать не тот огнетушитель или успеть локализовать очаг.',
    icon: BoltIcon,
  },
  {
    title: 'Обратная связь сразу в моменте',
    description:
      'Пользователь получает подсказки, а методист видит, где участник тормозит, ошибается или пропускает критический шаг.',
    icon: ChatBubbleLeftRightIcon,
  },
  {
    title: 'Безопасная тренировка навыка',
    description:
      'Команда ошибается в VR, а не на производстве. Это позволяет повторять обучение часто и без операционных рисков.',
    icon: ShieldCheckIcon,
  },
];

const steps = [
  'Подключение к сценарию и краткий инструктаж',
  'Реакция на возгорание и выбор протокола',
  'Разбор сессии с аналитикой по времени и ошибкам',
];

export default function CardsSection() {
  return (
    <section
      id='features'
      className='px-4 py-12 sm:px-6 lg:px-8 lg:py-16'
    >
      <div className='mx-auto max-w-7xl space-y-8'>
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: '-80px' }}
          transition={{ duration: 0.6 }}
          className='flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between'
        >
          <div>
            <div className='status-badge'>Продукт</div>
            <h2 className='mt-5 max-w-3xl text-3xl font-bold tracking-tight text-stone-950 dark:text-stone-50 sm:text-5xl'>
              Минималистичный интерфейс с акцентом на
              <span className='gradient-text'> прохождение, аналитику и ясность</span>
            </h2>
          </div>

          <p className='max-w-xl text-base leading-8 text-stone-600 dark:text-stone-300'>
            Интерфейс не спорит с VR-опытом, а дополняет его: быстрые входные
            точки, компактная навигация и плавные состояния без визуального шума.
          </p>
        </motion.div>

        <div className='grid gap-5 md:grid-cols-2 xl:grid-cols-4'>
          {features.map((feature, index) => {
            const Icon = feature.icon;

            return (
              <motion.div
                key={feature.title}
                initial={{ opacity: 0, y: 28 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: '-80px' }}
                transition={{ duration: 0.45, delay: index * 0.08 }}
                whileHover={{ y: -6 }}
                className='glass-panel group rounded-[32px] p-6'
              >
                <div className='flex h-12 w-12 items-center justify-center rounded-2xl bg-gradient-to-br from-orange-500 to-red-500 text-white shadow-[0_16px_30px_rgba(249,115,22,0.22)] transition-transform duration-300 group-hover:scale-105'>
                  <Icon className='h-6 w-6' />
                </div>
                <h3 className='mt-6 text-xl font-semibold text-stone-950 dark:text-stone-50'>
                  {feature.title}
                </h3>
                <p className='mt-3 text-sm leading-7 text-stone-600 dark:text-stone-300'>
                  {feature.description}
                </p>
              </motion.div>
            );
          })}
        </div>

        <motion.div
          id='experience'
          initial={{ opacity: 0, y: 28 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: '-80px' }}
          transition={{ duration: 0.55 }}
          className='grid gap-6 lg:grid-cols-[0.95fr_1.05fr]'
        >
          <div className='surface-panel rounded-[34px] p-7 sm:p-8'>
            <div className='status-badge'>Flow</div>
            <h3 className='mt-5 text-3xl font-semibold text-stone-950 dark:text-stone-50'>
              Путь пользователя от входа до итогового разбора
            </h3>
            <div className='mt-8 space-y-4'>
              {steps.map((step, index) => (
                <div
                  key={step}
                  className='flex items-start gap-4 rounded-[28px] border border-black/5 bg-white/50 p-4 dark:border-white/10 dark:bg-white/5'
                >
                  <div className='mt-0.5 flex h-9 w-9 items-center justify-center rounded-full bg-stone-950 text-sm font-semibold text-white dark:bg-stone-50 dark:text-stone-950'>
                    {index + 1}
                  </div>
                  <div className='text-sm font-medium leading-7 text-stone-700 dark:text-stone-200'>
                    {step}
                  </div>
                </div>
              ))}
            </div>
          </div>

          <div className='glass-panel overflow-hidden rounded-[34px] p-7 sm:p-8'>
            <div className='flex items-center justify-between gap-4'>
              <div>
                <div className='text-xs uppercase tracking-[0.28em] text-stone-500 dark:text-stone-400'>
                  Analytics snapshot
                </div>
                <h3 className='mt-3 text-2xl font-semibold text-stone-950 dark:text-stone-50'>
                  После сессии сразу видно, где провалился алгоритм действий
                </h3>
              </div>
              
            </div>

            <div className='mt-8 grid gap-4 sm:grid-cols-3'>
              {[
                { value: '82%', label: 'Верный порядок шагов' },
                { value: '01:48', label: 'Время до локализации' },
                { value: '2', label: 'Критические ошибки' },
              ].map((item) => (
                <div
                  key={item.label}
                  className='rounded-[28px] border border-black/5 bg-white/55 p-4 dark:border-white/10 dark:bg-white/5'
                >
                  <div className='font-display text-2xl font-semibold text-stone-950 dark:text-stone-50'>
                    {item.value}
                  </div>
                  <div className='mt-2 text-sm text-stone-500 dark:text-stone-400'>
                    {item.label}
                  </div>
                </div>
              ))}
            </div>

            <div className='mt-6 rounded-[30px] border border-orange-500/15 bg-gradient-to-br from-orange-500/12 via-transparent to-red-500/10 p-5'>
              <div className='text-sm font-semibold text-stone-900 dark:text-stone-50'>
                Сильная сторона интерфейса
              </div>
              <p className='mt-2 text-sm leading-7 text-stone-600 dark:text-stone-300'>
                Даже при большом количестве движущихся частей всё сведено к
                понятным карточкам, коротким решениям и плавным состояниям без
                визуального перегруза.
              </p>
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  );
}
