import type { AppProps } from 'next/app';
import { Manrope, Space_Grotesk } from 'next/font/google';

import '../styles/globals.css';

import { AuthProvider } from '../contexts/AuthContext';
import { ThemeProvider } from '../contexts/ThemeContext';

const manrope = Manrope({
  subsets: ['latin', 'cyrillic'],
  variable: '--font-manrope',
});

const spaceGrotesk = Space_Grotesk({
  subsets: ['latin'],
  variable: '--font-space-grotesk',
});

export default function App({ Component, pageProps }: AppProps) {
  return (
    <AuthProvider>
      <ThemeProvider>
        <div className={`${manrope.variable} ${spaceGrotesk.variable}`}>
          <Component {...pageProps} />
        </div>
      </ThemeProvider>
    </AuthProvider>
  );
}
