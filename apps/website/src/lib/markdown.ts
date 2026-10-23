import type { Root, Element, ElementContent, Properties } from "hast";
import { toText } from "hast-util-to-text";
import { visit } from "unist-util-visit";
import { icons } from "./icons";
const text = (value: string): ElementContent => ({ type: "text", value });
const el = (
  tagName: string,
  properties: Properties = {},
  children: ElementContent[] = [],
): Element => ({ type: "element", tagName, properties, children });
const svg = (name: string): Element =>
  el(
    "svg",
    {
      className: ["d-icon"],
      viewBox: "0 0 24 24",
      fill: "none",
      stroke: "currentColor",
      strokeWidth: "1.6",
      strokeLinecap: "round",
      strokeLinejoin: "round",
      ariaHidden: "true",
    },
    [{ type: "raw", value: icons[name] } as unknown as ElementContent],
  );
function highlight(source: string): ElementContent[] {
  const nodes: ElementContent[] = [];
  const pattern = /(\/\/[^\n]*)|('[^'\n]*')|\b(await|for|final|in)\b/g;
  let cursor = 0;
  for (const match of source.matchAll(pattern)) {
    if (match.index! > cursor)
      nodes.push(text(source.slice(cursor, match.index)));
    const kind = match[1] ? "comment" : match[2] ? "string" : "keyword";
    nodes.push(el("span", { className: [`syntax-${kind}`] }, [text(match[0])]));
    cursor = match.index! + match[0].length;
  }
  if (cursor < source.length) nodes.push(text(source.slice(cursor)));
  return nodes;
}
/** Retain the existing code controls and anchors while rendering Markdown. */
export function genuineMarkdown() {
  return (tree: Root, file: { path?: string }) => {
    const docs = /[/\\]docs[/\\]/.test(file.path ?? "");
    const ja = /[/\\]ja[/\\]/.test(file.path ?? "");
    const copyLabel = ja ? "コードをコピー" : "Copy code";
    const ids = new Set<string>();
    visit(tree, "element", (node) => {
      if (!/^h[1-6]$/.test(node.tagName)) return;
      const title = toText(node);
      let base = title
        .toLowerCase()
        .trim()
        .replace(/[^a-z0-9 _-]/g, "")
        .replace(/\s/g, "-");
      if (!base) base = title.trim().replace(/\s+/g, "-") || "heading";
      let id = base,
        suffix = 2;
      while (ids.has(id)) id = `${base}-${suffix++}`;
      ids.add(id);
      node.properties.id = id;
      node.properties.anchor = "true";
      node.children = [
        el("span", {}, node.children),
        el(
          "a",
          {
            href: `#${id}`,
            dataHeadingAnchor: "",
            ariaLabel: ja ? `${title}へのリンク` : `Link to ${title}`,
          },
          [],
        ),
      ];
    });
    visit(tree, "element", (node, index, parent) => {
      if (node.tagName === "pre" && parent && index !== undefined) {
        const code = node.children[0];
        if (code?.type !== "element" || code.tagName !== "code") return;
        const source = toText(code, { whitespace: "pre" }).replace(/\n$/, "");
        const dart = (
          code.properties.className as string[] | undefined
        )?.includes("language-dart");
        code.children = dart ? highlight(source) : [text(source)];
        const copy = el(
          "button",
          {
            type: "button",
            ariaLabel: copyLabel,
            [docs ? "dataDocCopy" : "dataBlogCopy"]: "",
          },
          [
            svg("copy"),
            ...(docs ? [el("span", {}, [text(ja ? "コピー" : "Copy")])] : []),
          ],
        );
        const children: ElementContent[] = docs
          ? [
              el("div", { className: ["d-doc-code-bar"] }, [
                el("span", {}, [
                  svg(dart ? "code" : "terminal"),
                  text(dart ? "Dart" : "Terminal"),
                ]),
                el(
                  "div",
                  {
                    className: ["d-code-theme-toggle"],
                    role: "group",
                    ariaLabel: ja
                      ? "コードサンプルの背景"
                      : "Code sample background",
                  },
                  ["light", "dark"].map((theme) =>
                    el(
                      "button",
                      {
                        type: "button",
                        dataCodeThemeChoice: theme,
                        ariaPressed: String(theme === "light"),
                      },
                      [text(theme === "light" ? "Light" : "Dark")],
                    ),
                  ),
                ),
                copy,
              ]),
              node,
            ]
          : [copy, node];
        parent.children[index] = el(
          "div",
          {
            className: docs
              ? ["code-block", "d-article-code", "d-code-surface"]
              : ["code-block"],
            ...(docs ? { dataCodeTheme: "light" } : {}),
          },
          children,
        );
        return "skip";
      }
    });
  };
}
