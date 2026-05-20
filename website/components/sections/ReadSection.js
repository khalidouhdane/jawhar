"use client";

import { BookOpen, Mic, Moon } from "lucide-react";
import FeatureSlider from "../shared/FeatureSlider";

export default function ReadSection() {
  const features = [
    {
      title: "Full Mushaf",
      description: "Read in the traditional 604-page Madani layout with a searchable index of 114 surahs.",
      icon: BookOpen
    },
    {
      title: "40+ Reciters",
      description: "Synchronized audio recitation with verse highlighting and a flexible reciter selector drawer.",
      icon: Mic
    },
    {
      title: "Focus Mode",
      description: "Toggle light, dark, or sepia themes, adjust font weights, and set your daily page werd.",
      icon: Moon
    }
  ];

  const slides = [
    {
      left: "/images/screenshots/mushaf_verse_menu.png",
      right: "/images/screenshots/read_index_home.png"
    },
    {
      left: "/images/screenshots/mushaf_audio_playing.png",
      right: "/images/screenshots/reciter_selection_sheet.png"
    },
    {
      left: "/images/screenshots/appearance_settings_sheet.png",
      right: "/images/screenshots/daily_werd_setup_sheet.png"
    }
  ];

  return (
    <FeatureSlider
      sectionId="read-section"
      title="Read, beautifully."
      description="Begin with the Mushaf itself: Hafs or Warsh, the full Madani page, and recitation that follows the verse you are reading."
      layout="left"
      features={features}
      slides={slides}
      accentColor="#0a72ef"
    />
  );
}

