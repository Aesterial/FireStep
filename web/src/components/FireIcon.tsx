export default function FireIcon() {
  return (
    <svg
      width='28'
      height='34'
      viewBox='0 0 28 34'
      fill='none'
      xmlns='http://www.w3.org/2000/svg'
    >
      <path
        d='M14 0C14 0 6 9 4 16C2 23 5.5 30 14 34C22.5 30 26 23 24 16C22 9 14 0 14 0Z'
        fill='url(#fire_outer)'
      />
      <path
        d='M14 12C14 12 10 18 10 22C10 26 12 28 14 30C16 28 18 26 18 22C18 18 14 12 14 12Z'
        fill='url(#fire_inner)'
      />
      <defs>
        <linearGradient
          id='fire_outer'
          x1='14'
          y1='0'
          x2='14'
          y2='34'
          gradientUnits='userSpaceOnUse'
        >
          <stop stopColor='#FDE68A' />
          <stop offset='0.4' stopColor='#FB923C' />
          <stop offset='1' stopColor='#EF4444' />
        </linearGradient>
        <linearGradient
          id='fire_inner'
          x1='14'
          y1='12'
          x2='14'
          y2='30'
          gradientUnits='userSpaceOnUse'
        >
          <stop stopColor='#FEF3C7' />
          <stop offset='1' stopColor='#FBBF24' />
        </linearGradient>
      </defs>
    </svg>
  );
}
