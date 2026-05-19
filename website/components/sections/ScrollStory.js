"use client";

import WisprFlowHero from '../explore/WisprFlowHero';
import ProblemSection from './ProblemSection';
import ReadSection from './ReadSection';
import UnderstandSection from './UnderstandSection';
import MemorizeSection from './MemorizeSection';
import DifferenceSection from './DifferenceSection';
import ClosingSection from './ClosingSection';

export default function ScrollStory() {
  return (
    <div style={{ position: 'relative' }}>
      <div style={{ position: 'relative', zIndex: 1 }}>
        <WisprFlowHero />
        <div className="section-divider" />
        <ProblemSection />
        <div className="section-divider" />
        <ReadSection />
        <div className="section-divider" />
        <UnderstandSection />
        <div className="section-divider" />
        <MemorizeSection />
        <div className="section-divider" />
        <DifferenceSection />
        <div className="section-divider" />
        <ClosingSection />
      </div>
    </div>
  );
}
