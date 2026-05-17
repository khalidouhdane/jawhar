"use client";

import { useState } from 'react';
import styles from './explore.module.css';
import dynamic from 'next/dynamic';

// Dynamically import components to avoid SSR issues with Three.js/GSAP
const WisprFlowHero = dynamic(() => import('../../components/explore/WisprFlowHero'), { ssr: false });
const BookHero = dynamic(() => import('../../components/explore/BookHero'), { ssr: false });
const ThreeDiamondHero = dynamic(() => import('../../components/explore/ThreeDiamondHero'), { ssr: false });
const GsapDiamondHero = dynamic(() => import('../../components/explore/GsapDiamondHero'), { ssr: false });

const EXPLORATIONS = [
  { id: 'wispr', label: 'Wispr Scroll Flow', component: WisprFlowHero },
  { id: 'threejs', label: '3D Diamond (Three.js)', component: ThreeDiamondHero },
  { id: 'book', label: 'SVG Book Pages', component: BookHero },
  { id: 'gsap', label: 'GSAP Diamond', component: GsapDiamondHero },
];

export default function ExplorePage() {
  const [activeTab, setActiveTab] = useState(EXPLORATIONS[0].id);

  const ActiveComponent = EXPLORATIONS.find(e => e.id === activeTab)?.component || EXPLORATIONS[0].component;

  return (
    <div className={styles.exploreContainer}>
      <nav className={styles.exploreNav}>
        {EXPLORATIONS.map((tab) => (
          <button
            key={tab.id}
            className={`${styles.exploreTab} ${activeTab === tab.id ? styles.activeTab : ''}`}
            onClick={() => setActiveTab(tab.id)}
          >
            {tab.label}
          </button>
        ))}
      </nav>
      
      <main className={styles.exploreContent}>
        <ActiveComponent />
      </main>
    </div>
  );
}
