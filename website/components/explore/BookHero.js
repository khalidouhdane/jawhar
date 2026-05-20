"use client";

import { useState } from 'react';
import styles from './ExploreComponents.module.css';
import { motion } from 'framer-motion';

export default function BookHero() {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <div className={styles.essenceContainer} style={{ height: 'calc(100vh - 120px)', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
      
      <div style={{ textAlign: 'center', marginBottom: '4rem', zIndex: 10 }}>
        <h2 style={{ fontSize: '3rem', color: 'var(--color-white)', letterSpacing: '-0.04em' }}>The Opening</h2>
        <p style={{ color: 'var(--color-gray-500)', fontSize: '1.25rem', maxWidth: '600px', margin: '1rem auto' }}>
          An exploration of the physical act of opening the Book, translated into digital space.
        </p>
        <button 
          onClick={() => setIsOpen(!isOpen)}
          style={{
            marginTop: '2rem',
            padding: '0.75rem 2rem',
            background: 'var(--color-white)',
            color: 'var(--color-black)',
            border: 'none',
            borderRadius: '999px',
            fontSize: '1rem',
            fontWeight: 500,
            cursor: 'pointer'
          }}
        >
          {isOpen ? 'Close Book' : 'Open Book'}
        </button>
      </div>

      {/* Book Container - 3D space */}
      <div style={{ perspective: '2000px', width: '600px', height: '400px', position: 'relative' }}>
        
        {/* The Book (acting as the spine center) */}
        <motion.div 
          style={{ 
            width: '100%', 
            height: '100%', 
            position: 'absolute', 
            transformStyle: 'preserve-3d',
            display: 'flex'
          }}
          initial={{ rotateY: 0 }}
          animate={{ rotateY: isOpen ? 0 : -20 }}
          transition={{ duration: 1.5, ease: [0.22, 1, 0.36, 1] }}
        >
          {/* Left Page (Back cover / resting page) */}
          <div style={{
            flex: 1,
            background: 'var(--color-gray-900)',
            border: '1px solid var(--shadow-ring)',
            borderRight: 'none',
            borderRadius: '12px 0 0 12px',
            boxShadow: 'inset -10px 0 20px rgba(0,0,0,0.5)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: '2rem',
            color: 'var(--color-gray-500)'
          }}>
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: isOpen ? 1 : 0 }} transition={{ delay: 0.5 }}>
              <h3>Surah Al-Fatiha</h3>
              <p style={{ marginTop: '1rem', fontSize: '0.875rem' }}>The Opening. Revealed in Mecca. 7 Verses.</p>
            </motion.div>
          </div>

          {/* Right Page (Front cover that flips) */}
          <div style={{ flex: 1, perspective: '2000px', transformOrigin: 'left center' }}>
            <motion.div 
              style={{
                width: '100%',
                height: '100%',
                background: 'var(--color-black)',
                border: '1px solid var(--shadow-ring)',
                borderLeft: 'none',
                borderRadius: '0 12px 12px 0',
                transformOrigin: 'left center',
                boxShadow: 'inset 10px 0 20px rgba(0,0,0,0.5), 20px 0 50px rgba(0,0,0,0.5)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                backfaceVisibility: 'hidden',
                position: 'absolute',
                zIndex: 2
              }}
              initial={{ rotateY: 0 }}
              animate={{ rotateY: isOpen ? -180 : 0 }}
              transition={{ duration: 1.5, ease: [0.22, 1, 0.36, 1] }}
            >
              {/* Cover Design */}
              <div style={{ textAlign: 'center' }}>
                <h2 style={{ fontFamily: 'var(--font-serif)', fontSize: '2.5rem', color: 'var(--color-gray-500)' }}>جوهر</h2>
              </div>
            </motion.div>

            {/* Revealed Right Page (Under the cover) */}
            <div style={{
              width: '100%',
              height: '100%',
              background: 'var(--color-gray-900)',
              border: '1px solid var(--shadow-ring)',
              borderLeft: '1px solid rgba(255,255,255,0.05)',
              borderRadius: '0 12px 12px 0',
              boxShadow: 'inset 10px 0 20px rgba(0,0,0,0.5)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              padding: '2rem',
              position: 'absolute',
              zIndex: 1
            }}>
               <motion.div initial={{ opacity: 0 }} animate={{ opacity: isOpen ? 1 : 0 }} transition={{ delay: 0.5 }}>
                  <p style={{ fontFamily: 'var(--font-serif)', fontSize: '1.5rem', lineHeight: 2, textAlign: 'right', color: 'var(--color-white)' }}>
                    بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ
                  </p>
                  <p style={{ marginTop: '2rem', fontSize: '0.875rem', color: 'var(--color-gray-500)' }}>
                    In the name of Allah, the Entirely Merciful, the Especially Merciful.
                  </p>
                </motion.div>
            </div>
          </div>

        </motion.div>
      </div>

    </div>
  );
}
