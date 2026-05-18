import { existsSync, readFileSync } from "node:fs";

const read = (path) => readFileSync(new URL(`../${path}`, import.meta.url), "utf8");
const assert = (condition, message) => {
  if (!condition) {
    throw new Error(message);
  }
};

const scrollStory = read("components/sections/ScrollStory.js");
const hero = read("components/explore/WisprFlowHero.js");
const footer = read("components/layout/Footer.js");
const navbar = read("components/layout/Navbar.js");
const download = read("app/download/page.js");
const downloadLayout = read("app/download/layout.js");
const hackathon = read("app/hackathon/page.js");

assert(
  existsSync(new URL("../components/sections/WaitlistSection.js", import.meta.url)),
  "WaitlistSection.js should exist"
);
assert(
  scrollStory.includes("WaitlistSection") && scrollStory.includes("<WaitlistSection />"),
  "Homepage should render the waitlist section"
);
assert(
  hero.includes('href="#waitlist"'),
  "Hero CTA should point to the waitlist section"
);
assert(
  hero.includes("Closed source for now") &&
    footer.includes("Closed source for now") &&
    download.includes("Closed source for now") &&
    downloadLayout.includes("Closed source for now"),
  "Public copy should consistently say closed source for now"
);
assert(
  !footer.includes("Open source") &&
    !footer.includes("github.com/khalidouhdane/le-quran") &&
    !download.includes("fully open source") &&
    !download.includes("View on GitHub"),
  "Open-source source-code claims should be removed"
);
assert(
  navbar.includes('/#read-section') && !navbar.includes('/#system'),
  "Features navigation should target an existing homepage section"
);
assert(
  existsSync(new URL("../app/privacy/page.js", import.meta.url)) &&
    existsSync(new URL("../app/terms/page.js", import.meta.url)),
  "Privacy and terms pages should exist"
);
assert(
  !hackathon.includes("revolutionary") &&
    !hackathon.includes("state-of-the-art") &&
    !hackathon.includes("Demo Video Placeholder") &&
    hackathon.includes("Use the homepage for the hackathon review"),
  "Hackathon page should use calmer, concrete wording and point reviewers to the homepage"
);
