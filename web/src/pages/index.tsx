import Head from 'next/head';

import CardsSection from '../components/CardsSection';
import Footer from '../components/Footer';
import HeroSection from '../components/HeroSection';
import Navbar from '../components/Navbar';

export default function Home() {
  return (
    <>
      <Head>
        <title>FireStep - VR тренажёр пожарной безопасности</title>
        <meta
          name='description'
          content='VR-тренажёр для безопасной отработки действий при возгорании на производстве.'
        />
        <meta name='viewport' content='width=device-width, initial-scale=1' />
        <link rel='icon' href='/favicon.ico' />
      </Head>

      <div className='min-h-screen'>
        <Navbar />
        <HeroSection />
        <CardsSection />
        <Footer />
      </div>
    </>
  );
}
