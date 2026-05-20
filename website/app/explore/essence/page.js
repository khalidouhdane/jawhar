"use client";

import dynamic from 'next/dynamic';

const EssenceFlowHero = dynamic(
  () => import('../../../components/explore/EssenceFlowHero'),
  { ssr: false }
);

export default function EssencePage() {
  return (
    <>
      {/* Hide nav/footer from first paint — GSAP animates them in */}
      <style>{`nav, footer { opacity: 0; }`}</style>
      <EssenceFlowHero />
    </>
  );
}
