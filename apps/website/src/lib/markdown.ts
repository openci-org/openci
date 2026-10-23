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
/** Add site controls around Astro's heading IDs and Shiki code blocks. */
export function genuineMarkdown() {
  return (tree: Root, file: { path?: string }) => {
    const docs = /[/\\]docs[/\\]/.test(file.path ?? "");
    const ja = /[/\\]ja[/\\]/.test(file.path ?? "");
    const copyLabel = ja ? "コードをコピー" : "Copy code";
    visit(tree, "element", (node) => {
      if (!/^h[1-6]$/.test(node.tagName)) return;
      const title = toText(node);
      const id = node.properties.id;
      if (typeof id !== "string") return;
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
        const dart = node.properties.dataLanguage === "dart";
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
