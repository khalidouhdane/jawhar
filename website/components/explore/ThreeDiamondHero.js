"use client";

import { useRef } from 'react';
import { Canvas, useFrame } from '@react-three/fiber';
import { Environment, Float, PresentationControls, ContactShadows } from '@react-three/drei';
import styles from './ExploreComponents.module.css';

function DiamondModel() {
  const meshRef = useRef(null);

  useFrame((state, delta) => {
    if (meshRef.current) {
      meshRef.current.rotation.y += delta * 0.2;
    }
  });

  return (
    <Float speed={2} rotationIntensity={0.5} floatIntensity={1}>
      <mesh ref={meshRef} position={[0, 0, 0]} castShadow>
        {/* Octahedron scaled to look like a gem */}
        <octahedronGeometry args={[1.5, 0]} />
        <meshPhysicalMaterial 
          color="#ffffff"
          transmission={0.9}
          opacity={1}
          metalness={0.1}
          roughness={0.1}
          ior={2.4}
          thickness={1.5}
          envMapIntensity={2}
          clearcoat={1}
          clearcoatRoughness={0.1}
        />
      </mesh>
    </Float>
  );
}

export default function ThreeDiamondHero() {
  return (
    <div className={styles.wisprContainer} style={{ height: 'calc(100vh - 120px)', display: 'flex', flexDirection: 'column' }}>
      <div style={{ textAlign: 'center', paddingTop: '4rem', zIndex: 10, position: 'relative' }}>
        <h2 style={{ fontSize: '3rem', color: 'var(--color-white)', letterSpacing: '-0.04em' }}>The 3D Core</h2>
        <p style={{ color: 'var(--color-gray-500)', fontSize: '1.25rem', maxWidth: '600px', margin: '1rem auto' }}>
          Exploring interactive, real-time 3D rendering for the brand centerpiece using Three.js and Fiber.
        </p>
      </div>

      <div style={{ flex: 1, width: '100%', position: 'relative' }}>
        <Canvas shadows camera={{ position: [0, 0, 5], fov: 45 }}>
          <color attach="background" args={['#000']} />
          <ambientLight intensity={0.5} />
          <spotLight position={[10, 10, 10]} angle={0.15} penumbra={1} intensity={2} castShadow />
          
          <PresentationControls 
            global 
            config={{ mass: 2, tension: 500 }} 
            snap={{ mass: 4, tension: 1500 }} 
            rotation={[0, 0.3, 0]} 
            polar={[-Math.PI / 3, Math.PI / 3]} 
            azimuth={[-Math.PI / 1.4, Math.PI / 2]}
          >
            <DiamondModel />
          </PresentationControls>

          <Environment preset="city" />
          <ContactShadows position={[0, -2.5, 0]} opacity={0.5} scale={10} blur={2} far={4} color="#ffffff" />
        </Canvas>
      </div>
    </div>
  );
}
