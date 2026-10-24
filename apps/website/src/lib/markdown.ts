import type { Root, Element, ElementContent, Properties } from "hast";
import { toText } from "hast-util-to-text";
import { visit } from "unist-util-visit";
import { unified, rehypeHeadingIds } from "@astrojs/markdown-remark";
import { icons } from "./icons";

/** Let Starlight extend the docs pipeline while retaining the blog renderer. */
export function websiteMarkdown(): ReturnType<typeof unified> {
  const docs = unified({ smartypants: false });
  const blog = unified({
    smartypants: false,
    rehypePlugins: [rehypeHeadingIds, genuineMarkdown],
  });
  return {
    ...docs,
    async createRenderer(shared) {
      const [docsRenderer, blogRenderer] = await Promise.all([
        docs.createRenderer(shared),
        blog.createRenderer({ ...shared, syntaxHighlight: "shiki" }),
      ]);
      return {
        render(content, options) {
          const isBlog = /\/content\/[^/]+\/blog\//.test(
            options?.fileURL?.pathname ?? "",
          );
          return (isBlog ? blogRenderer : docsRenderer).render(
            content,
            options,
          );
        },
      };
    },
  };
}

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
function genuineMarkdown() {
  return (tree: Root, file: { path?: string }) => {
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
        const copy = el(
          "button",
          {
            type: "button",
            ariaLabel: copyLabel,
            dataBlogCopy: "",
          },
          [svg("copy")],
        );
        parent.children[index] = el("div", { className: ["code-block"] }, [
          copy,
          node,
        ]);
        return "skip";
      }
    });
  };
}
