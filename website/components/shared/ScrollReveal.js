"use client";
import { useRef } from "react";
import { motion, useInView } from "framer-motion";

/**
 * Scroll-triggered reveal wrapper.
 * Supports: fade-up (default), fade, scale, slide-left, slide-right
 */
export default function ScrollReveal({
  children,
  delay = 0,
  y = 24,
  variant = "fade-up",
  once = true,
  className = "",
}) {
  const ref = useRef(null);
  const isInView = useInView(ref, { once, margin: "-60px" });

  const variants = {
    "fade-up": {
      hidden: { opacity: 0, y },
      visible: { opacity: 1, y: 0 },
    },
    fade: {
      hidden: { opacity: 0 },
      visible: { opacity: 1 },
    },
    scale: {
      hidden: { opacity: 0, scale: 0.95 },
      visible: { opacity: 1, scale: 1 },
    },
    "slide-left": {
      hidden: { opacity: 0, x: -32 },
      visible: { opacity: 1, x: 0 },
    },
    "slide-right": {
      hidden: { opacity: 0, x: 32 },
      visible: { opacity: 1, x: 0 },
    },
  };

  const v = variants[variant] || variants["fade-up"];

  return (
    <motion.div
      ref={ref}
      initial="hidden"
      animate={isInView ? "visible" : "hidden"}
      variants={v}
      transition={{
        duration: 0.7,
        delay,
        ease: [0.22, 1, 0.36, 1],
      }}
      className={className}
    >
      {children}
    </motion.div>
  );
}
