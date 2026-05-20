"use client";

import { BookOpen, Globe, Info } from "lucide-react";
import FeatureSlider from "../shared/FeatureSlider";

export default function UnderstandSection() {
  const features = [
    {
      title: "Translations",
      description: "View English translations inline on the page or explore translations of key thematic verses.",
      icon: Globe
    },
    {
      title: "Tafsir",
      description: "Access brief and detailed commentary in a clean bottom drawer directly from any verse.",
      icon: BookOpen
    },
    {
      title: "Context & Stories",
      description: "Discover Surah introductions, Reasons of Revelation, and historical Quranic stories.",
      icon: Info
    }
  ];

  const slides = [
    {
      left: "/images/screenshots/mushaf_inline_translation.png",
      right: "/images/screenshots/story_musa_key_verses.png"
    },
    {
      left: "/images/screenshots/tafsir_sheet_brief.png",
      right: "/images/screenshots/understand_index_home.png"
    },
    {
      left: "/images/screenshots/surah_intro_asbab_nuzul.png",
      right: "/images/screenshots/story_musa_overview.png"
    }
  ];

  return (
    <FeatureSlider
      sectionId="understand-section"
      title="Understand every verse."
      description="Meaning is not an add-on. Translation, tafsir, reasons of revelation, and surah introductions sit beside the verse so memory has context."
      layout="right"
      features={features}
      slides={slides}
      accentColor="#de1d8d"
    />
  );
}

