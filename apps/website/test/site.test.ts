import assert from "node:assert/strict";
import { readFileSync, readdirSync, existsSync } from "node:fs";
import { createHash } from "node:crypto";
import { test } from "node:test";
import { runInNewContext } from "node:vm";
import { load } from "cheerio";
const read = (file: string) => readFileSync(file, "utf8");
const files = (readdirSync("dist", { recursive: true }) as string[]).filter(
  (f) => /^(en|ja)\/.*index\.html$/.test(f),
);
const pages = new Map(
  files.map((f) => [
    "/" + f.replace(/index\.html$/, ""),
    load(read("dist/" + f)),
  ]),
);
const contentRoutes = (readdirSync("content", { recursive: true }) as string[])
  .filter((file) => file.endsWith(".md"))
  .map((file) => "/" + file.replace(/(?:\/index)?\.md$/, "") + "/");
const digest = (text: string) =>
  createHash("sha256").update(text).digest("hex");
const fences = (source: string) =>
  [...source.matchAll(/^```([^\n]*)\n([\s\S]*?)^```/gm)].map((m) => ({
    language: m[1].trim(),
    code: m[2].trimEnd(),
  }));

test("all content and localized landing pages are built", () => {
  assert.deepEqual(
    new Set(pages.keys()),
    new Set(["/en/", "/ja/", ...contentRoutes]),
  );
});
test("each blog article has its own localized 1200 x 630 PNG social image", () => {
  const imageHashes = new Set<string>();
  const articleImages: string[] = [];
  for (const [route, $] of pages) {
    if ($('meta[property="og:type"]').attr("content") !== "article") continue;
    const imagePath = `/ogp${route.replace(/\/$/, "")}.png`;
    const imageUrl = "https://genuineci.com" + imagePath;
    assert.equal($('meta[property="og:image"]').attr("content"), imageUrl);
    assert.equal($('meta[name="twitter:image"]').attr("content"), imageUrl);
    assert.equal(
      $('meta[property="og:image:type"]').attr("content"),
      "image/png",
    );
    assert.equal($('meta[property="og:image:width"]').attr("content"), "1200");
    assert.equal($('meta[property="og:image:height"]').attr("content"), "630");
    const title = $("h1").text().replace(/\s+/g, " ").trim();
    assert.equal($('meta[property="og:image:alt"]').attr("content"), title);
    assert.equal($('meta[name="twitter:image:alt"]').attr("content"), title);
    const image = readFileSync("dist" + imagePath);
    assert.equal(image.subarray(0, 8).toString("hex"), "89504e470d0a1a0a");
    assert.equal(image.readUInt32BE(16), 1200);
    assert.equal(image.readUInt32BE(20), 630);
    imageHashes.add(createHash("sha256").update(image).digest("hex"));
    articleImages.push(imagePath.slice("/ogp/".length));
  }
  assert.ok(articleImages.length > 0);
  assert.equal(
    imageHashes.size,
    articleImages.length,
    "articles or translations share an image",
  );
  const generated = (
    readdirSync("dist/ogp", { recursive: true }) as string[]
  ).filter((file) => file.endsWith(".png"));
  assert.deepEqual(new Set(generated), new Set(articleImages));
});
for (const [route, $] of pages) {
  test(`${route}: language, metadata, accessible structure, and assets`, () => {
    const locale = route.split("/")[1];
    assert.equal($("html").attr("lang"), locale);
    assert.equal($("main").length, 1);
    assert.equal($("h1").length, 1);
    assert.ok($("title").text().includes("GenuineCI"));
    assert.equal($("meta[name=robots]").attr("content"), "noindex, nofollow");
    assert.equal(
      $("link[rel=canonical]").attr("href"),
      "https://genuineci.com" + route,
    );
    assert.equal(
      $('meta[property="og:url"]').attr("content"),
      "https://genuineci.com" + route,
    );
    const image = $('meta[property="og:image"]').attr("content")!;
    assert.equal(new URL(image).origin, "https://genuineci.com");
    assert.ok(existsSync("dist" + new URL(image).pathname));
    assert.equal($('meta[name="twitter:image"]').attr("content"), image);
    assert.equal(
      $('meta[property="og:locale"]').attr("content"),
      locale === "en" ? "en_US" : "ja_JP",
    );
    for (const language of ["en", "ja", "x-default"]) {
      const href = $(`link[hreflang="${language}"]`).attr("href");
      const translatedPath = route.replace(
        /^\/(en|ja)\//,
        language === "ja" ? "/ja/" : "/en/",
      );
      assert.equal(
        href,
        pages.has(translatedPath)
          ? "https://genuineci.com" + translatedPath
          : undefined,
      );
      if (language !== "x-default") {
        const link = $(`.language-switcher [lang="${language}"]`);
        assert.equal(link.length, 1);
        assert.equal(
          link.attr("href"),
          pages.has(translatedPath) ? translatedPath : undefined,
        );
        assert.equal(
          link.attr("aria-disabled"),
          pages.has(translatedPath) ? undefined : "true",
        );
      }
    }
    assert.equal(
      $(".language-switcher [aria-current=page]").attr("lang"),
      locale,
    );
    const ids = $("[id]")
      .toArray()
      .map((e) => $(e).attr("id"));
    assert.equal(new Set(ids).size, ids.length, "duplicate IDs");
    assert.equal($("link[rel=icon]").attr("href"), "/favicon.png");
    for (const e of $("link[rel=stylesheet],script[src],img[src]").toArray()) {
      const src = $(e).attr("href") ?? $(e).attr("src")!;
      if (src.startsWith("/"))
        assert.ok(existsSync("dist" + src.split("?")[0]), src);
    }
    assert.equal($('script[src*="dart"],astro-island').length, 0);
    for (const a of $("a[href]").toArray()) {
      const href = $(a).attr("href")!;
      const target = new URL(href, "https://genuineci.com" + route);
      if (target.origin !== "https://genuineci.com") continue;
      const destination = pages.get(
        target.pathname.endsWith("/") ? target.pathname : target.pathname + "/",
      );
      assert.ok(destination, `${route} -> ${href}`);
      if (target.hash)
        assert.ok(
          destination("[id]")
            .toArray()
            .some(
              (e) =>
                destination(e).attr("id") ===
                decodeURIComponent(target.hash.slice(1)),
            ),
          `missing anchor: ${href}`,
        );
    }
  });
  if (route.includes("/docs/") || /\/blog\/.+/.test(route)) {
    test(`${route}: Markdown code and table of contents survive rendering`, () => {
      const stem = "content" + route.replace(/\/$/, "");
      const file = existsSync(stem + ".md") ? stem + ".md" : stem + "/index.md";
      const expected = fences(read(file)),
        blocks = $(".d-prose pre code,.article-body pre code").toArray();
      assert.equal(blocks.length, expected.length);
      blocks.forEach((e, i) => {
        assert.equal(digest($(e).text().trimEnd()), digest(expected[i].code));
        assert.equal(
          $(e).closest(".code-block").find("button[aria-label]").length,
          1,
        );
        assert.ok($(e).closest("pre").hasClass("astro-code"));
        assert.equal(
          $(e).closest("pre").attr("data-language"),
          expected[i].language || "plaintext",
        );
        assert.ok($(e).find(".line").length > 0, "Shiki code lines");
      });
      const selector = route.includes("/docs/")
        ? ".d-prose :header[id]"
        : ".article-body :header[id]";
      for (const h of $(selector).toArray()) {
        const id = $(h).attr("id");
        assert.equal($(h).find("[data-heading-anchor]").attr("href"), `#${id}`);
        assert.ok(
          $(".d-toc a,.article-sidebar a")
            .toArray()
            .some(
              (a) =>
                decodeURIComponent($(a).attr("href")?.split("#")[1] ?? "") ===
                id,
            ),
        );
      }
    });
  }
  if (route.includes("/docs/")) {
    test(`${route}: search and navigation remain in the current language`, () => {
      const entries = JSON.parse($("#docs-search-data").text());
      const docsPrefix = "/" + route.split("/")[1] + "/docs/";
      assert.deepEqual(
        new Set(entries.map((entry: { url: string }) => entry.url)),
        new Set(contentRoutes.filter((path) => path.startsWith(docsPrefix))),
      );
      for (const entry of entries) {
        assert.ok(entry.url.startsWith("/" + route.split("/")[1] + "/docs/"));
        assert.ok(pages.has(entry.url));
      }
      assert.equal(
        new Set(entries.map((e: { url: string }) => e.url)).size,
        entries.length,
      );
      const secrets = entries.filter((e: { body: string }) =>
        e.body.includes("secretFile"),
      );
      assert.ok(secrets.length > 0);
      const messages = JSON.parse($("#docs-ui-text").text());
      assert.ok(messages.results.includes("{count}"));
    });
  }
}
for (const locale of ["en", "ja"] as const) {
  test(`${locale}: landing and Docs samples use highlighted, copyable code`, () => {
    const landing = pages.get(`/${locale}/`)!;
    for (const name of ["flutter", "dart"]) {
      const sample = landing(
        `#workflow-${name} pre.astro-code[data-language=dart]`,
      );
      assert.equal(sample.length, 1);
      assert.ok(sample.find("code .line").length > 1);
    }
    assert.ok(
      landing("#workflow-dart code")
        .text()
        .includes("\n  await ci.run(command);\n}"),
    );
    const docs = pages.get(`/${locale}/docs/`)!;
    const home = docs("#home-code.astro-code[data-language=dart]");
    assert.equal(home.length, 1);
    assert.ok(home.find("code").text().includes("Future<void> main() async {"));
    assert.equal(
      home.closest(".d-home-code").find("[data-copy-home]").length,
      1,
    );
  });
  test(`${locale}: blog listing, dates and next article`, () => {
    const $ = pages.get(`/${locale}/blog/`)!;
    const links = $(".post-card-link")
      .toArray()
      .map((e) => $(e).attr("href"));
    assert.deepEqual(
      new Set(links),
      new Set(
        contentRoutes.filter(
          (path) =>
            path.startsWith(`/${locale}/blog/`) && path !== `/${locale}/blog/`,
        ),
      ),
    );
    assert.equal($(".featured-post").attr("href"), links[0]);
    for (const link of links) {
      assert.ok(link!.startsWith(`/${locale}/blog/`));
      const article = pages.get(link!)!;
      assert.ok(
        article(".article-next>a")
          .first()
          .attr("href")
          ?.startsWith(`/${locale}/blog/`),
      );
    }
    const dates = $(".post-card time")
      .toArray()
      .map((e) => $(e).attr("datetime"));
    assert.deepEqual(dates, [...dates].sort().reverse());
  });
  test(`${locale}: pricing terms and language links are preserved`, () => {
    const $ = pages.get(`/${locale}/`)!;
    const pricing = $("#pricing").text();
    for (const value of ["US$10", "US$100", "600", "6,000", "168"])
      assert.ok(pricing.includes(value), value);
    assert.equal($(".language-switcher a").length, 2);
    assert.equal(
      $(".language-switcher [aria-current=page]").attr("lang"),
      locale,
    );
  });
}
test("Japanese Markdown headings use Astro's generated IDs", () => {
  const $ = pages.get("/ja/docs/quickstart/")!;
  assert.deepEqual(
    $(".d-prose h2")
      .toArray()
      .map((heading) => $(heading).attr("id")),
    [
      "はじめる前に",
      "01-sdkを追加する",
      "02-ワークフローを書く",
      "03-ローカルで確かめる",
      "04-ciで動かす準備",
      "次にできること",
    ],
  );
});
test("all Shiki colors have matching CSS variables", () => {
  const styles = (readdirSync("dist/_astro") as string[])
    .filter((file) => file.endsWith(".css"))
    .map((file) => read("dist/_astro/" + file))
    .join("\n");
  for (const [route, $] of pages) {
    for (const element of $(
      ".astro-code[style],.astro-code [style]",
    ).toArray()) {
      for (const [name] of $(element)
        .attr("style")!
        .matchAll(/--astro-code-[a-z-]+/g)) {
        assert.ok(styles.includes(`${name}:`), `${route}: undefined ${name}`);
      }
    }
  }
});
for (const [route, hash, shared] of [
  ["/ja/", "#pricing", true],
  ["/en/blog/v2-3-0/", "#article-heading", false],
  ["/ja/docs/", "#guides", true],
] as const) {
  test(`${route}: language switching preserves queries and appropriate anchors`, () => {
    const location = new URL(
      "https://genuineci.com" + route + "?source=mail" + hash,
    );
    const $ = pages.get(route)!;
    const links = $("[data-language-link]")
      .toArray()
      .map((element) => {
        let href = $(element).attr("href")!;
        return {
          get href() {
            return new URL(href, location).href;
          },
          set href(value: string) {
            href = value;
          },
        };
      });
    const events = new Map<string, () => void>();
    runInNewContext(read("src/scripts/site.js"), {
      URL,
      document: {
        querySelectorAll: (selector: string) =>
          selector === "[data-language-link]" ? links : [],
      },
      window: {
        location,
        addEventListener: (event: string, listener: () => void) =>
          events.set(event, listener),
      },
    });
    for (const link of links) {
      const url = new URL(link.href);
      assert.equal(url.search, "?source=mail");
      assert.equal(url.hash, shared || url.pathname === route ? hash : "");
    }
    location.hash = "#another-heading";
    assert.ok(events.has("hashchange"));
    events.get("hashchange")!();
    for (const link of links) {
      const url = new URL(link.href);
      assert.equal(url.search, "?source=mail");
      assert.equal(url.hash, url.pathname === route ? "#another-heading" : "");
    }
  });
}
test("translated articles keep identical executable examples", () => {
  for (const file of readdirSync("content/en", {
    recursive: true,
  }) as string[]) {
    if (!file.endsWith(".md") || !existsSync("content/ja/" + file)) continue;
    assert.deepEqual(
      fences(read("content/en/" + file)),
      fences(read("content/ja/" + file)),
      file,
    );
  }
});
test("root redirect and legacy hosting routes retain their destinations", () => {
  assert.ok(read("dist/index.html").includes("url=/en/"));
  const hosting = JSON.parse(read("firebase.json")).hosting;
  assert.equal(hosting.public, "dist");
  assert.deepEqual(
    hosting.redirects.map(
      (r: { source: string; destination: string; type: number }) => [
        r.source,
        r.destination,
        r.type,
      ],
    ),
    [
      ["/", "/en/", 301],
      ["/blog", "/ja/blog/", 301],
      ["/blog/:path*", "/ja/blog/:path/", 301],
      ["/docs", "/ja/docs/", 301],
      ["/docs/:path*", "/ja/docs/:path/", 301],
    ],
  );
});
