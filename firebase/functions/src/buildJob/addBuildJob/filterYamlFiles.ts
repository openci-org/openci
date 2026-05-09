export function filterYamlFiles(
  entries: Array<{ type: string; name: string; path: string }>,
): Array<{ name: string; path: string }> {
  return entries.filter(
    (item) => item.type === "file" && (item.name.endsWith(".yaml") || item.name.endsWith(".yml")),
  );
}
