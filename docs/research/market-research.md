# Jawhar — Market & Competitive Research

*Compiled from 3 NotebookLM Deep Research Reports (230 sources) — May 2026*

> This is a reference document for strategic decisions. For the brand strategy derived from this research, see [brand-strategy.md](brand-strategy.md).

---

## 📓 NotebookLM Research Notebooks

| Notebook | Sources | Focus | Key Finding |
|----------|---------|-------|-------------|
| [Competitor Analysis](https://notebooklm.google.com/notebook/43c26df0-0878-4678-8b71-da13b9d6600b) | 73 | Direct competitors, feature gaps, positioning | No competitor combines adaptive planning + understanding layer |
| [App Naming & Brand](https://notebooklm.google.com/notebook/80c3ad20-23c2-43a7-aa2d-184044c50beb) | 82 | Naming conventions, linguistic analysis, brand identity | 239+ Islamic apps mapped; "linguistic bottleneck" in naming |
| [Market Gaps & Positioning](https://notebooklm.google.com/notebook/36b07248-90ad-401e-b332-dd1909959420) | 75 | Market sizing, user pain points, EdTech trends | 56% post-Ramadan uninstall rate; understanding is the retention lever |
| [Hackathon API Research](https://notebooklm.google.com/notebook/5be4ef03-eedd-4dde-a0d0-7610633d04a2) | 27 | Quran Foundation APIs, OAuth2 scopes, hackathon rules | User API requires OAuth2 PKCE; pre-prod keys for dev, production swap later |

---

## 📊 Market Sizing

| Metric | Value | Source |
|--------|-------|--------|
| Global Muslim population | **2+ billion** (25% of world) | DinarStandard 2025 |
| Muslim youth projected by 2030 | **540 million** (digital-native) | DinarStandard |
| Global halal economy | **$2.29T** consumer spending (2022) | SGIE Report |
| Global EdTech market (2024) | **$163.5B** → $658B by 2035 (13.5% CAGR) | Kaiser Research |
| GCC EdTech market (2024) | **$3.02B** → $4.47B by 2030 (6.74% CAGR) | MarkNtel Advisors |

---

## 🏆 Competitor Landscape

| App | Downloads | Core Tech | What they LACK |
|-----|-----------|-----------|---------------|
| **Tarteel AI** | 15M+ | AI Voice Recognition | No plan generation, no revision scheduling, no understanding layer |
| **Mathani** | 200K+ | SRS + Gamification | Too restrictive, no page-level work, no comprehension |
| **Retain Quran** | 1M+ | AI Flashcards + SRS | Flashcard-only, no structured methodology, no context |
| **Al Muhaffiz** | 50K+ | Traditional tracking | Dated UI, crashes, no AI, no adaptive planning |
| **Quran Companion** | N/A | Social + Plans | Community-focused, limited individual tracking |

**Universal gap:** No competitor offers adaptive daily plan generation + digital session mode + understanding layer (tafsir, translations, asbab al-nuzul) + mutashabihat practice + SRS flashcards in one app.

---

## 😤 User Pain Points (validated from Reddit & App Store reviews)

1. **"Hifz is 80% revision, but no app has revision logic"** — Apps track what you memorized but don't generate structured revision plans
2. **"I memorized Juz 30 but can't explain a single verse"** — Rote memorization without comprehension fails long-term
3. **"The same app over and over"** — 500+ Islamic apps, massive fatigue with copycat products
4. **"Ridiculous ads"** — Religious apps with aggressive ads feel exploitative
5. **No desktop support** — Serious students want PC/Mac for large-screen study
6. **Accent-intolerant AI** — West African/South Asian users get false error flags

---

## 📉 Post-Ramadan Retention Crisis

| Metric | Data |
|--------|------|
| Android uninstall rate (1 month post-download) | **56.44%** |
| Ramadan install surge | **+27% non-organic** |
| Pre-Ramadan acquisition advantage | **20% higher LTV** vs. peak-week users |

---

## 🎯 Jawhar's Validated Competitive Moat

| Feature | Jawhar | Tarteel | Mathani | Al Muhaffiz | Retain |
|---------|--------|---------|---------|-------------|--------|
| Adaptive daily plan generation | ✅ | ❌ | ❌ | ❌ | ❌ |
| Understanding layer (tafsir, asbab) | ✅ | ❌ | ❌ | ❌ | ❌ |
| Digital session mode | ✅ | ❌ | ❌ | ❌ | ❌ |
| SRS flashcards (6 types) | ✅ | ❌ | ❌ | ❌ | ✅ (basic) |
| Mutashabihat practice | ✅ | ❌ | ❌ | ❌ | ❌ |
| Desktop (Windows/Mac/Linux) | ✅ | ❌ | ❌ | ✅ | ❌ |
| B&W Quran-first design | ✅ | ❌ | ❌ | ❌ | ❌ |
| Quran Foundation API | ✅ | ❌ | ❌ | ❌ | ❌ |
| Free / No ads | ✅ | Freemium | Paid | Free | Ads |

---

## Hackathon Context

**Quran Foundation Hackathon** — Deadline: May 20, 2026 — $10K prize pool, 7 winners

### API Access Status (as of May 13, 2026)
- **Production Content API keys**: ✅ Active — used for all current features
- **Pre-Production User API keys**: ✅ Active — for developing User API integration
- **Production User API keys**: Pending — Quran Foundation confirmed "quick swap" once ready
- **Hybrid approach confirmed**: Keep production keys for Content API, use pre-prod for User API development

### Judging Criteria
- Innovation
- API Usage (Content + User APIs)
- User Impact
- Technical Excellence
- Design

---

*Last updated: May 13, 2026*
