import type { Metadata } from "next";
import { StudioHomePage } from "../../../components/site";
import { createPageMetadata } from "../../../lib/seo";

export const metadata: Metadata = createPageMetadata({
  title: "OpenCI Studio",
  description:
    "OpenCI Studioは、数人規模の会社から大企業まで、様々な規模のプロジェクトに対応できるFlutterの開発スタジオです。",
  path: "/studio/",
});

export default function StudioPage() {
  return <StudioHomePage />;
}
