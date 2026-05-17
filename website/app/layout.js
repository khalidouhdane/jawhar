import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import Navbar from "../components/layout/Navbar";
import Footer from "../components/layout/Footer";
import ThemeProvider from "../components/shared/ThemeProvider";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
  display: "swap",
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
  display: "swap",
});

export const metadata = {
  title: "Jawhar — Memorize with Meaning",
  description:
    "The first Quran memorization companion built on understanding. Adaptive daily plans, structured sessions, translations, tafsir, and spaced repetition — all in one app.",
  keywords: [
    "Quran memorization",
    "hifz app",
    "memorize quran",
    "quran tafsir",
    "sabaq sabqi manzil",
    "jawhar",
    "quran study",
    "islamic education",
  ],
  authors: [{ name: "Jawhar" }],
  openGraph: {
    title: "Jawhar — Memorize with Meaning",
    description:
      "The first Quran memorization companion built on understanding.",
    type: "website",
    locale: "en_US",
    siteName: "Jawhar",
  },
  twitter: {
    card: "summary_large_image",
    title: "Jawhar — Memorize with Meaning",
    description:
      "The first Quran memorization companion built on understanding.",
  },
  robots: {
    index: true,
    follow: true,
  },
};

export default function RootLayout({ children }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <link
          href="https://fonts.googleapis.com/css2?family=Amiri:ital,wght@0,400;0,700;1,400;1,700&display=swap"
          rel="stylesheet"
        />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{
            __html: JSON.stringify({
              "@context": "https://schema.org",
              "@type": "SoftwareApplication",
              name: "Jawhar",
              description:
                "The first Quran memorization companion built on understanding.",
              applicationCategory: "EducationalApplication",
              operatingSystem: "Windows, Android, macOS, iOS, Linux, Web",
              offers: {
                "@type": "Offer",
                price: "0",
                priceCurrency: "USD",
              },
            }),
          }}
        />
      </head>
      <body className={`${geistSans.variable} ${geistMono.variable}`}>
        <ThemeProvider>
          <Navbar />
          {children}
          <Footer />
        </ThemeProvider>
      </body>
    </html>
  );
}
