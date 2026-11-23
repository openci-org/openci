// These section IDs are shared by both translations of the product pages.
const sharedAnchors = new Set([
  "main",
  "estimate",
  "playground",
  "apis",
  "quickstart",
  "comparison",
  "faq",
  "features",
  "workflow",
  "pipeline",
  "integrations",
  "pricing",
  "get-started",
  "start",
  "guides",
  "special-thanks",
  "sponsors",
  "machines",
  "infrastructure",
  "write-dart",
  "open-source",
]);

export function languageHref(
  target: string,
  location: Pick<URL, "pathname" | "hash" | "search">,
) {
  const hash =
    target === location.pathname || sharedAnchors.has(location.hash.slice(1))
      ? location.hash
      : "";
  return target + location.search + hash;
}
