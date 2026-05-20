"use client";

import { useEffect, useRef } from 'react';
import styles from './ExploreComponents.module.css';
import gsap from 'gsap';

export default function GsapDiamondHero() {
  const containerRef = useRef(null);
  const facetsRef = useRef([]);

  useEffect(() => {
    // Clear any existing animations
    gsap.killTweensOf(facetsRef.current);

    // Initial state
    gsap.set(facetsRef.current, { 
      opacity: 0, 
      scale: 0, 
      transformOrigin: "center center",
      rotation: () => Math.random() * 90 - 45
    });

    // Create timeline
    const tl = gsap.timeline({ repeat: -1, yoyo: true, repeatDelay: 1 });

    tl.to(facetsRef.current, {
      opacity: 1,
      scale: 1,
      rotation: 0,
      duration: 1.5,
      stagger: {
        each: 0.1,
        from: "center",
        grid: "auto"
      },
      ease: "elastic.out(1, 0.5)"
    })
    .to(facetsRef.current, {
      y: () => Math.random() * 20 - 10,
      duration: 2,
      ease: "sine.inOut",
      stagger: 0.05
    }, "-=0.5");

    return () => tl.kill();
  }, []);

  const addToRefs = (el) => {
    if (el && !facetsRef.current.includes(el)) {
      facetsRef.current.push(el);
    }
  };

  return (
    <div className={styles.essenceContainer} style={{ height: 'calc(100vh - 120px)', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
      
      <div style={{ textAlign: 'center', marginBottom: '4rem', zIndex: 10 }}>
        <h2 style={{ fontSize: '3rem', color: 'var(--color-white)', letterSpacing: '-0.04em' }}>GSAP Sequencing</h2>
        <p style={{ color: 'var(--color-gray-500)', fontSize: '1.25rem', maxWidth: '600px', margin: '1rem auto' }}>
          Using GSAP timelines to orchestrate complex, staggered animations for SVG facets.
        </p>
      </div>

      <div ref={containerRef} style={{ width: '400px', height: '400px', position: 'relative' }}>
        <svg viewBox="0 0 400 400" fill="none" xmlns="http://www.w3.org/2000/svg" style={{ width: '100%', height: '100%', overflow: 'visible' }}>
          {/* Top facets */}
          <polygon ref={addToRefs} points="200,60 120,140 200,160" fill="#4a4a4a" />
          <polygon ref={addToRefs} points="200,60 280,140 200,160" fill="#3a3a3a" />
          <polygon ref={addToRefs} points="120,140 60,140 200,160" fill="#2a2a2a" />
          <polygon ref={addToRefs} points="280,140 340,140 200,160" fill="#333333" />
          <polygon ref={addToRefs} points="200,60 120,140 60,140" fill="#1f1f1f" />
          <polygon ref={addToRefs} points="200,60 280,140 340,140" fill="#141414" />
          
          {/* Bottom facets */}
          <polygon ref={addToRefs} points="200,340 120,140 200,160" fill="#2a2a2a" />
          <polygon ref={addToRefs} points="200,340 280,140 200,160" fill="#1f1f1f" />
          <polygon ref={addToRefs} points="200,340 120,140 60,140" fill="#141414" />
          <polygon ref={addToRefs} points="200,340 280,140 340,140" fill="#0f0f0f" />
        </svg>
      </div>
      
    </div>
  );
}
