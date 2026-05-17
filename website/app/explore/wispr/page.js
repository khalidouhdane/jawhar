"use client";

import dynamic from 'next/dynamic';

const WisprFlowHero = dynamic(
  () => import('../../../components/explore/WisprFlowHero'),
  { ssr: false }
);

export default function WisprPage() {
  return (
    <>
      {/* Hide nav/footer from first paint — GSAP animates them in */}
      <style>{`nav, footer { opacity: 0; }`}</style>
      <WisprFlowHero />
    </>
  );
}
