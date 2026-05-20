"use client";

import EssenceFlowHero from '../explore/EssenceFlowHero';
import ProblemSection from './ProblemSection';
import ReadSection from './ReadSection';
import UnderstandSection from './UnderstandSection';
import MemorizeSection from './MemorizeSection';
import StrategySection from './StrategySection';
import ClosingSection from './ClosingSection';

export default function ScrollStory() {
  return (
    <div style={{ position: 'relative' }}>
      <div style={{ position: 'relative', zIndex: 1 }}>
        <EssenceFlowHero />
        <ProblemSection />
        <ReadSection />
        <UnderstandSection />
        <MemorizeSection />
        <StrategySection />
        <ClosingSection />
      </div>
    </div>
  );
}
