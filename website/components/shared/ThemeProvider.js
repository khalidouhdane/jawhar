"use client";
import { ThemeProvider as NextThemesProvider } from "next-themes";

/**
 * Wrapper around next-themes ThemeProvider.
 * - attribute="data-theme" sets [data-theme="dark|light"] on <html>
 * - defaultTheme="dark" makes dark mode the default
 * - enableSystem=false — we control the theme, not the OS
 */
export default function ThemeProvider({ children }) {
  return (
    <NextThemesProvider
      attribute="data-theme"
      defaultTheme="dark"
      enableSystem={false}
      disableTransitionOnChange={false}
    >
      {children}
    </NextThemesProvider>
  );
}
