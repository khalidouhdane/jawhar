import { existsSync, readFileSync } from "node:fs";

const read = (path) => readFileSync(new URL(`../${path}`, import.meta.url), "utf8");
const assert = (condition, message) => {
  if (!condition) {
    throw new Error(message);
  }
};

const scrollStory = read("components/sections/ScrollStory.js");
const hero = read("components/explore/EssenceFlowHero.js");
const footer = read("components/layout/Footer.js");
const navbar = read("components/layout/Navbar.js");
const download = read("app/download/page.js");
const downloadLayout = read("app/download/layout.js");

assert(
  scrollStory.includes("ProblemSection") && scrollStory.includes("<ProblemSection />"),
  "Homepage should render the problem section before the feature tour"
);
assert(
  hero.includes('href="/download"'),
  "Hero CTA should point to the download page"
);
assert(
  hero.includes("The first Quran memorization companion built on understanding."),
  "Hero subtitle should carry the meaning-first thesis"
);
assert(
  !hero.includes("Verse in. Meaning out.") &&
    !hero.includes("Free forever"),
  "Hero copy should stay precise and avoid gimmicky taglines or broad claims"
);
assert(
  footer.includes("Closed source for now") &&
    download.includes("Closed source for now") &&
    downloadLayout.includes("Closed source for now"),
  "Supporting public copy should consistently say closed source for now"
);
assert(
  !footer.includes("Open source") &&
    !footer.includes("github.com/khalidouhdane/jawhar") &&
    !download.includes("fully open source") &&
    !download.includes("View on GitHub"),
  "Open-source source-code claims should be removed"
);
assert(
  navbar.includes('/#read-section') && !navbar.includes('/#system'),
  "Features navigation should target an existing homepage section"
);
const readSection = read("components/sections/ReadSection.js");
const understandSection = read("components/sections/UnderstandSection.js");
const memorizeSection = read("components/sections/MemorizeSection.js");
const problemSection = read("components/sections/ProblemSection.js");

const landingCopy = [readSection, understandSection, memorizeSection, problemSection].join("\n");
for (const phrase of [
  "like never before",
  "moment of peace",
  "unbreakable habit",
  "adaptive intelligence",
]) {
  assert(
    !landingCopy.includes(phrase),
    `Landing copy should avoid generic marketing phrase: ${phrase}`
  );
}
assert(
  problemSection.includes("Meaning is not extra") &&
    understandSection.includes("Meaning is not an add-on"),
  "Problem and Understand sections should carry the meaning-first thesis"
);
assert(
  existsSync(new URL("../app/privacy/page.js", import.meta.url)) &&
    existsSync(new URL("../app/terms/page.js", import.meta.url)),
  "Privacy and terms pages should exist"
);

