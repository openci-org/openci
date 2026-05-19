import type { Metadata } from "next";
import { CicdPage } from "../../../components/site";
import { createPageMetadata } from "../../../lib/seo";

export const metadata: Metadata = createPageMetadata({
  title: "OpenCI — CI/CD that's faster and cheaper.",
  description:
    "Blazing-fast builds on M4 Mac Mini. Up to 90% cheaper than GitHub Actions. Your existing workflow files just work.",
  path: "/en/",
  locale: "en_US",
});

export default function EnglishLandingPage() {
  return <CicdPage lang="en" />;
}
