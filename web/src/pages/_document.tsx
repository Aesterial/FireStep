import { Head, Html, Main, NextScript } from 'next/document';

export default function Document() {
  return (
    <Html lang='ru' suppressHydrationWarning>
      <Head />
      <body className='antialiased'>
        <script
          dangerouslySetInnerHTML={{
            __html: `
              try {
                var t = localStorage.getItem('firestep-theme');
                if (t === 'light') {
                  document.documentElement.classList.remove('dark');
                } else {
                  document.documentElement.classList.add('dark');
                }
              } catch (e) {}
            `,
          }}
        />
        <Main />
        <NextScript />
      </body>
    </Html>
  );
}
