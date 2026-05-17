"use client";
import { motion } from "framer-motion";
import { useTheme } from "next-themes";
import { useEffect, useState } from "react";
import styles from "./DiamondAnimation.module.css";

/*
 * Diamond crystal with gradient facets, inner glow, and shimmer.
 * Each facet is a separate motion path that assembles from scattered positions.
 * Facet colors adapt to theme: bright/crystalline in dark, subtle in light.
 */

const darkFacets = [
  // Top crown facets — bright, crystalline
  { d: "M100,12 L130,55 L100,48 Z", fill: "#444444", delay: 0.0 },
  { d: "M100,12 L70,55 L100,48 Z", fill: "#4a4a4a", delay: 0.05 },
  { d: "M100,12 L130,55 L155,50 Z", fill: "#3d3d3d", delay: 0.1 },
  { d: "M100,12 L70,55 L45,50 Z", fill: "#424242", delay: 0.15 },

  // Upper body facets
  { d: "M45,50 L70,55 L55,100 L30,85 Z", fill: "#363636", delay: 0.2 },
  { d: "M155,50 L130,55 L145,100 L170,85 Z", fill: "#333333", delay: 0.25 },
  { d: "M70,55 L100,48 L100,105 L55,100 Z", fill: "#484848", delay: 0.3 },
  { d: "M130,55 L100,48 L100,105 L145,100 Z", fill: "#404040", delay: 0.35 },

  // Lower body facets
  { d: "M30,85 L55,100 L100,105 L65,140 Z", fill: "#2e2e2e", delay: 0.4 },
  { d: "M170,85 L145,100 L100,105 L135,140 Z", fill: "#2a2a2a", delay: 0.45 },

  // Bottom point facets
  { d: "M65,140 L100,105 L100,190 Z", fill: "#383838", delay: 0.5 },
  { d: "M135,140 L100,105 L100,190 Z", fill: "#303030", delay: 0.55 },
];

const lightFacets = [
  // Top crown facets
  { d: "M100,12 L130,55 L100,48 Z", fill: "#e8e8e8", delay: 0.0 },
  { d: "M100,12 L70,55 L100,48 Z", fill: "#f0f0f0", delay: 0.05 },
  { d: "M100,12 L130,55 L155,50 Z", fill: "#dcdcdc", delay: 0.1 },
  { d: "M100,12 L70,55 L45,50 Z", fill: "#e4e4e4", delay: 0.15 },

  // Upper body facets
  { d: "M45,50 L70,55 L55,100 L30,85 Z", fill: "#d4d4d4", delay: 0.2 },
  { d: "M155,50 L130,55 L145,100 L170,85 Z", fill: "#d0d0d0", delay: 0.25 },
  { d: "M70,55 L100,48 L100,105 L55,100 Z", fill: "#ebebeb", delay: 0.3 },
  { d: "M130,55 L100,48 L100,105 L145,100 Z", fill: "#e0e0e0", delay: 0.35 },

  // Lower body facets
  { d: "M30,85 L55,100 L100,105 L65,140 Z", fill: "#c8c8c8", delay: 0.4 },
  { d: "M170,85 L145,100 L100,105 L135,140 Z", fill: "#c0c0c0", delay: 0.45 },

  // Bottom point facets
  { d: "M65,140 L100,105 L100,190 Z", fill: "#d8d8d8", delay: 0.5 },
  { d: "M135,140 L100,105 L100,190 Z", fill: "#cccccc", delay: 0.55 },
];

/* Randomize scatter origin for each facet */
function getScatter() {
  const angle = Math.random() * Math.PI * 2;
  const dist = 80 + Math.random() * 120;
  return {
    x: Math.cos(angle) * dist,
    y: Math.sin(angle) * dist,
  };
}

export default function DiamondAnimation() {
  const { resolvedTheme } = useTheme();
  const [mounted, setMounted] = useState(false);
  useEffect(() => setMounted(true), []);

  const isDark = !mounted || resolvedTheme === "dark";
  const facets = isDark ? darkFacets : lightFacets;
  const strokeColor = isDark ? "rgba(255,255,255,0.08)" : "rgba(0,0,0,0.04)";
  const outlineStroke = isDark ? "rgba(255,255,255,0.1)" : "rgba(0,0,0,0.06)";
  const shimmerColor = isDark ? "rgba(255,255,255,0.4)" : "rgba(255,255,255,0.6)";

  return (
    <div className={styles.wrapper}>
      {/* Ambient glow behind diamond */}
      <div className={styles.glow} />

      <motion.svg
        viewBox="0 0 200 200"
        fill="none"
        className={styles.diamond}
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 1.2, ease: [0.22, 1, 0.36, 1] }}
      >
        {/* Subtle outline — appears after assembly */}
        <motion.path
          d="M100,12 L155,50 L170,85 L145,100 L135,140 L100,190 L65,140 L55,100 L30,85 L45,50 Z"
          stroke={outlineStroke}
          strokeWidth="0.5"
          fill="none"
          initial={{ pathLength: 0 }}
          animate={{ pathLength: 1 }}
          transition={{ duration: 2.5, delay: 1.2, ease: "easeOut" }}
        />

        {/* Facets assembling */}
        {facets.map((facet, i) => {
          const scatter = getScatter();
          return (
            <motion.path
              key={i}
              d={facet.d}
              fill={facet.fill}
              stroke={strokeColor}
              strokeWidth="0.5"
              initial={{
                opacity: 0,
                x: scatter.x,
                y: scatter.y,
                scale: 0.3,
                rotate: (Math.random() - 0.5) * 90,
              }}
              animate={{
                opacity: 1,
                x: 0,
                y: 0,
                scale: 1,
                rotate: 0,
              }}
              transition={{
                duration: 1.4,
                delay: 0.3 + facet.delay * 2,
                ease: [0.22, 1, 0.36, 1],
              }}
            />
          );
        })}

        {/* Inner highlight line — shimmer effect */}
        <motion.line
          x1="60"
          y1="40"
          x2="85"
          y2="95"
          stroke={shimmerColor}
          strokeWidth="1.5"
          strokeLinecap="round"
          initial={{ opacity: 0 }}
          animate={{ opacity: [0, 0.8, 0] }}
          transition={{
            duration: 3,
            delay: 2.5,
            repeat: Infinity,
            repeatDelay: 6,
          }}
        />
      </motion.svg>
    </div>
  );
}
