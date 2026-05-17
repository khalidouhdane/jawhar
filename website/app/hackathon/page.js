import React from 'react';
import Link from 'next/link';
import { ArrowRight, PlayCircle, BookOpen, Layers, CheckCircle2, ShieldCheck, Database, RefreshCw } from 'lucide-react';

export default function HackathonPage() {
  return (
    <div className="min-h-screen bg-black text-white selection:bg-white selection:text-black">
      <main className="pt-8 pb-24">
        {/* Hero Section */}
        <section className="max-w-5xl mx-auto px-6 text-center space-y-8">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-white/10 bg-white/5 text-xs font-medium tracking-wide uppercase">
            <span className="w-2 h-2 rounded-full bg-white animate-pulse"></span>
            Quran Foundation Hackathon 2026 Submission
          </div>
          
          <h1 className="text-5xl md:text-7xl font-bold tracking-tighter leading-tight">
            Memorize with <span className="text-transparent bg-clip-text bg-gradient-to-r from-white to-white/50">Meaning.</span>
          </h1>
          
          <p className="text-xl text-white/60 max-w-2xl mx-auto leading-relaxed">
            A revolutionary Hifz companion that shifts the focus from rote memorization to profound comprehension, powered by the Quran Foundation API ecosystem.
          </p>

          <div className="flex flex-col sm:flex-row items-center justify-center gap-4 pt-8">
            <Link href="/" className="h-12 px-8 rounded-full bg-white text-black flex items-center gap-2 font-medium hover:bg-white/90 transition-colors">
              <PlayCircle className="w-5 h-5" />
              Watch Demo Video
            </Link>
            <Link href="https://github.com/khalidouhdane/jawhar" target="_blank" className="h-12 px-8 rounded-full border border-white/20 flex items-center gap-2 font-medium hover:bg-white/5 transition-colors">
              <ShieldCheck className="w-5 h-5" />
              View Source Code
            </Link>
          </div>
        </section>

        {/* Video Placeholder */}
        <section className="max-w-5xl mx-auto px-6 mt-24">
          <div className="aspect-video w-full rounded-2xl border border-white/10 bg-white/5 relative overflow-hidden group shadow-[0_0_50px_rgba(255,255,255,0.05)]">
            <div className="absolute inset-0 flex flex-col items-center justify-center text-white/40 group-hover:text-white/60 transition-colors">
              <PlayCircle className="w-16 h-16 mb-4 opacity-50" />
              <p className="font-medium">Demo Video Placeholder</p>
              <p className="text-sm mt-2">2-3 Minute Walkthrough</p>
            </div>
            {/* Actual video iframe would go here */}
          </div>
        </section>

        {/* API Usage Section */}
        <section className="max-w-5xl mx-auto px-6 mt-32 space-y-16">
          <div className="text-center space-y-4">
            <h2 className="text-3xl font-bold tracking-tight">API Ecosystem Integration</h2>
            <p className="text-white/60 max-w-2xl mx-auto">
              Jawhar leverages both the Content and User APIs to deliver a seamless, state-of-the-art memorization experience.
            </p>
          </div>

          <div className="grid md:grid-cols-2 gap-8">
            {/* Content API Card */}
            <div className="p-8 rounded-2xl border border-white/10 bg-white/[0.02] hover:bg-white/[0.04] transition-colors relative overflow-hidden group">
              <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-white/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity"></div>
              <Database className="w-8 h-8 mb-6" />
              <h3 className="text-xl font-bold mb-4">Content API (v4)</h3>
              <ul className="space-y-4">
                <li className="flex items-start gap-3">
                  <CheckCircle2 className="w-5 h-5 text-white/40 shrink-0 mt-0.5" />
                  <p className="text-white/70 text-sm leading-relaxed"><strong className="text-white">Gapless Audio:</strong> Chapter-level audio with <code className="text-xs bg-white/10 px-1 rounded">?segments=true</code> powers real-time verse highlighting.</p>
                </li>
                <li className="flex items-start gap-3">
                  <CheckCircle2 className="w-5 h-5 text-white/40 shrink-0 mt-0.5" />
                  <p className="text-white/70 text-sm leading-relaxed"><strong className="text-white">Dynamic Context:</strong> Localized translations and brief/detailed Tafsir fetched instantly on verse tap.</p>
                </li>
                <li className="flex items-start gap-3">
                  <CheckCircle2 className="w-5 h-5 text-white/40 shrink-0 mt-0.5" />
                  <p className="text-white/70 text-sm leading-relaxed"><strong className="text-white">Pixel-Perfect Mushaf:</strong> Madani page layout data correctly paginates 604 pages of the Arabic text.</p>
                </li>
              </ul>
            </div>

            {/* User API Card */}
            <div className="p-8 rounded-2xl border border-white/10 bg-white/[0.02] hover:bg-white/[0.04] transition-colors relative overflow-hidden group">
              <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-white/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity"></div>
              <RefreshCw className="w-8 h-8 mb-6" />
              <h3 className="text-xl font-bold mb-4">User API (OAuth2 PKCE)</h3>
              <ul className="space-y-4">
                <li className="flex items-start gap-3">
                  <CheckCircle2 className="w-5 h-5 text-white/40 shrink-0 mt-0.5" />
                  <p className="text-white/70 text-sm leading-relaxed"><strong className="text-white">Seamless Authentication:</strong> Secure login via Quran.com using the OAuth 2.0 PKCE flow.</p>
                </li>
                <li className="flex items-start gap-3">
                  <CheckCircle2 className="w-5 h-5 text-white/40 shrink-0 mt-0.5" />
                  <p className="text-white/70 text-sm leading-relaxed"><strong className="text-white">Unified Bookmarks:</strong> Bi-directional syncing of bookmarks and collections with the main platform.</p>
                </li>
                <li className="flex items-start gap-3">
                  <CheckCircle2 className="w-5 h-5 text-white/40 shrink-0 mt-0.5" />
                  <p className="text-white/70 text-sm leading-relaxed"><strong className="text-white">Progress Tracking:</strong> Reading sessions and activity days automatically sync, preserving user streaks.</p>
                </li>
              </ul>
            </div>
          </div>
        </section>

        {/* The 3 Pillars */}
        <section className="max-w-5xl mx-auto px-6 mt-32">
          <div className="text-center space-y-4 mb-16">
            <h2 className="text-3xl font-bold tracking-tight">The Three Pillars</h2>
            <p className="text-white/60 max-w-2xl mx-auto">
              How Jawhar encodes the essence of the Quran into your daily life.
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-6">
            <div className="p-6 border border-white/10 rounded-2xl">
              <Layers className="w-6 h-6 mb-4 text-white/60" />
              <h4 className="font-bold mb-2">1. The Plan</h4>
              <p className="text-sm text-white/60">Adaptive daily plans (Sabaq, Sabqi, Manzil) generated by AI to match your pace.</p>
            </div>
            <div className="p-6 border border-white/10 rounded-2xl">
              <PlayCircle className="w-6 h-6 mb-4 text-white/60" />
              <h4 className="font-bold mb-2">2. The Session</h4>
              <p className="text-sm text-white/60">Distraction-free digital mode tracking repetitions, time, and self-assessment.</p>
            </div>
            <div className="p-6 border border-white/10 rounded-2xl">
              <BookOpen className="w-6 h-6 mb-4 text-white/60" />
              <h4 className="font-bold mb-2">3. The Understanding</h4>
              <p className="text-sm text-white/60">Instant access to translations, Tafsir, and Asbab al-Nuzul without breaking flow.</p>
            </div>
          </div>
        </section>

      </main>
    </div>
  );
}
