import assert from "node:assert/strict";
import { readFileSync, readdirSync, existsSync, statSync } from "node:fs";
import { createHash } from "node:crypto";
import { test } from "node:test";
import { runInNewContext } from "node:vm";
import { load } from "cheerio";
import CanvasKitInit from "canvaskit-wasm/full";
import { formatRuntimeEstimate } from "../src/lib/pricing.ts";
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
const contentFiles = new Map(
  ["content", "src/content/docs"].flatMap((base) =>
    (readdirSync(base, { recursive: true }) as string[])
      .filter((file) => /\.mdx?$/.test(file))
      .map(
        (file) =>
          [
            "/" + file.replace(/(?:\/index)?\.mdx?$/, "") + "/",
            base + "/" + file,
          ] as const,
      ),
  ),
);
const contentRoutes = [...contentFiles.keys()];
const legacyRedirectPrefixes = (
  JSON.parse(read("firebase.json")).hosting.redirects as { source: string }[]
)
  .filter(({ source }) => source.endsWith("/:path*"))
  .map(({ source }) => source.slice(0, -":path*".length));
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
    new Set(["/en/", "/ja/", "/en/pricing/", "/ja/pricing/", ...contentRoutes]),
  );
});
test("Starlight retains all sixteen documentation URLs and indexes both languages", () => {
  const guides = [
    "",
    "quickstart/",
    "workflows/",
    "triggers/",
    "flutter/",
    "secrets/",
    "cli/",
    "self-hosting/",
  ];
  const index = JSON.parse(read("dist/pagefind/pagefind-entry.json"));
  assert.deepEqual(Object.keys(index.languages).sort(), ["en", "ja"]);
  for (const locale of ["en", "ja"]) {
    const routes = guides.map((guide) => `/${locale}/docs/${guide}`);
    assert.deepEqual(
      new Set(
        contentRoutes.filter((route) => route.startsWith(`/${locale}/docs/`)),
      ),
      new Set(routes),
    );
    assert.equal(index.languages[locale].page_count, guides.length);
    routes.forEach((route, i) => {
      const $ = pages.get(route)!;
      const pagination = $(".pagination-links a")
        .toArray()
        .map((e) => $(e).attr("href"));
      assert.deepEqual(
        pagination,
        [routes[i - 1], routes[i + 1]].filter(Boolean),
      );
    });
  }
});
test("each blog article has its own localized 1200 x 630 PNG social image", () => {
  const imageHashes = new Set<string>();
  const articleImages: string[] = [];
  for (const [route, $] of pages) {
    if ($('meta[property="og:type"]').attr("content") !== "article") continue;
    const imagePath = `/ogp${route.replace(/\/$/, "")}.png`;
    const imageUrl = "https://openci.org" + imagePath;
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
test("the original release image URLs still serve JPEGs", () => {
  for (const slug of ["v2-1-0", "v2-2-0", "v2-3-0"]) {
    const image = readFileSync(`dist/ogp/${slug}.jpg`);
    assert.equal(image.subarray(0, 3).toString("hex"), "ffd8ff");
    assert.equal(image.subarray(-2).toString("hex"), "ffd9");
  }
});
test("social cards show the article cover and keep the footer inside the image", async () => {
  const skia = await CanvasKitInit();
  const pixelFormat = {
    colorSpace: skia.ColorSpace.SRGB,
    colorType: skia.ColorType.RGBA_8888,
    alphaType: skia.AlphaType.Unpremul,
  };
  for (const [route, $] of pages) {
    if ($('meta[property="og:type"]').attr("content") !== "article") continue;
    const cover = skia.MakeImageFromEncoded(
      readFileSync("dist" + $(".post-cover img").attr("src")),
    );
    const card = skia.MakeImageFromEncoded(
      readFileSync(
        "dist" +
          new URL($('meta[property="og:image"]').attr("content")!).pathname,
      ),
    );
    assert.ok(cover && card, route);
    try {
      const panelWidth = 548;
      const scale = Math.max(panelWidth / cover.width(), 630 / cover.height());
      for (const [u, v] of [
        [0.25, 0.25],
        [0.5, 0.5],
        [0.75, 0.75],
      ]) {
        const x = Math.floor(u * panelWidth),
          y = Math.floor(v * 630);
        const sourceX = Math.round(
          cover.width() / 2 + (x + 0.5 - panelWidth / 2) / scale - 0.5,
        );
        const sourceY = Math.round(
          cover.height() / 2 + (y + 0.5 - 315) / scale - 0.5,
        );
        const pixel = { ...pixelFormat, width: 1, height: 1 };
        const actual = card.readPixels(x, y, pixel);
        const expected = cover.readPixels(sourceX, sourceY, pixel);
        assert.ok(actual && expected, route);
        // Cubic resampling can change the nearest source pixel's color.
        assert.ok(
          actual.every((value, i) => Math.abs(value - expected[i]) < 36),
          route,
        );
      }
      const footer = card.readPixels(600, 550, {
        ...pixelFormat,
        width: 548,
        height: 36,
      });
      const bottom = card.readPixels(600, 590, {
        ...pixelFormat,
        width: 548,
        height: 40,
      });
      assert.ok(
        footer?.some((channel, i) => i % 4 === 0 && channel < 100),
        route,
      );
      assert.ok(
        bottom?.every((channel, i) => i % 4 !== 0 || channel === 250),
        route,
      );
    } finally {
      cover.delete();
      card.delete();
    }
  }
});
for (const [route, $] of pages) {
  test(`${route}: language, metadata, accessible structure, and assets`, () => {
    const locale = route.split("/")[1];
    assert.equal($("html").attr("lang"), locale);
    assert.equal($("main").length, 1);
    assert.equal($("h1").length, 1);
    const isProduct = !route.includes("/docs/");
    assert.ok(
      $("title")
        .text()
        .includes(isProduct ? "OpenCI" : "OpenCI Docs"),
    );
    if (isProduct) {
      assert.equal(
        $('meta[property="og:site_name"]').attr("content"),
        "OpenCI",
      );
      assert.equal($(".product-nav .wordmark").text().trim(), "OpenCI");
      assert.equal($(".product-footer").length, 1);
    }
    assert.equal($("meta[name=robots]").attr("content"), "noindex, nofollow");
    assert.equal(
      $("link[rel=canonical]").attr("href"),
      "https://openci.org" + route,
    );
    assert.equal(
      $('meta[property="og:url"]').attr("content"),
      "https://openci.org" + route,
    );
    const image = $('meta[property="og:image"]').attr("content")!;
    assert.equal(new URL(image).origin, "https://openci.org");
    if ($('meta[property="og:type"]').attr("content") !== "article") {
      assert.equal(new URL(image).pathname, "/ogp/openci.jpg");
    }
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
          ? "https://openci.org" + translatedPath
          : undefined,
      );
      if (language !== "x-default" && !route.includes("/docs/")) {
        const links = $(`.language-switcher [lang="${language}"]`);
        assert.equal(links.length, 1);
        for (const element of links.toArray()) {
          assert.equal(
            $(element).attr("href"),
            pages.has(translatedPath) ? translatedPath : undefined,
          );
          assert.equal(
            $(element).attr("aria-disabled"),
            pages.has(translatedPath) ? undefined : "true",
          );
        }
      }
    }
    if (route.includes("/docs/")) {
      const selects = $("starlight-lang-select select");
      assert.equal(selects.length, 2);
      assert.equal($(".language-switcher,[data-language-link]").length, 0);
      for (const select of selects.toArray()) {
        assert.equal($(select).find("option[selected]").attr("value"), route);
        assert.deepEqual(
          $(select)
            .find("option")
            .toArray()
            .map((option) => ({
              value: $(option).attr("value"),
              label: $(option).text(),
            })),
          ["en", "ja"].map((language) => ({
            value: route.replace(/^\/(en|ja)\//, `/${language}/`),
            label: language === "en" ? "English" : "日本語",
          })),
        );
      }
    } else {
      assert.equal(
        $(".language-switcher [aria-current=page]").attr("lang"),
        locale,
      );
    }
    const ids = $("[id]")
      .toArray()
      .map((e) => $(e).attr("id"));
    assert.equal(new Set(ids).size, ids.length, "duplicate IDs");
    assert.equal($("link[rel~=icon]").attr("href"), "/favicon.png");
    for (const e of $("link[rel=stylesheet],script[src],img[src]").toArray()) {
      const src = $(e).attr("href") ?? $(e).attr("src")!;
      if (src.startsWith("/")) {
        assert.ok(
          !legacyRedirectPrefixes.some((prefix) => src.startsWith(prefix)),
          `${route} -> ${src}: asset is intercepted by a Hosting redirect`,
        );
        assert.ok(existsSync("dist" + src.split("?")[0]), src);
      }
    }
    assert.equal($('script[src*="dart"],astro-island').length, 0);
    for (const a of $("a[href]").toArray()) {
      const href = $(a).attr("href")!;
      const target = new URL(href, "https://openci.org" + route);
      if (target.origin !== "https://openci.org") continue;
      const destination = pages.get(
        target.pathname.endsWith("/") ? target.pathname : target.pathname + "/",
      );
      if (!destination && !target.hash) {
        // Studio and the release archive are built by the companion Next.js workspace.
        if (existsSync(`../landing_page/app/(ja)${target.pathname}page.tsx`))
          continue;
        const asset = "dist" + decodeURIComponent(target.pathname);
        assert.ok(
          existsSync(asset) && statSync(asset).isFile(),
          `${route} -> ${href}`,
        );
        continue;
      }
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
      const isDocs = route.includes("/docs/");
      const expected = fences(read(contentFiles.get(route)!)),
        blocks = $(
          ".sl-markdown-content pre code,.article-body pre code",
        ).toArray();
      assert.equal(blocks.length, expected.length);
      blocks.forEach((e, i) => {
        const code = isDocs
          ? $(e)
              .find(".ec-line .code")
              .toArray()
              .map((line) => $(line).text().replace(/\n$/, ""))
              .join("\n")
          : $(e).text();
        assert.equal(digest(code.trimEnd()), digest(expected[i].code));
        const wrapper = $(e).closest(
          isDocs ? ".expressive-code" : ".code-block",
        );
        assert.equal(
          wrapper.find("button[aria-label],button[title]").length,
          1,
        );
        if (isDocs) {
          assert.equal(
            wrapper
              .find("button[data-code]")
              .attr("data-code")!
              .replaceAll("\u007f", "\n"),
            expected[i].code,
          );
          assert.equal(
            wrapper.find("button[title]").attr("title"),
            route.startsWith("/ja/") ? "コードをコピー" : "Copy to clipboard",
          );
        }
        if (!isDocs) assert.ok($(e).closest("pre").hasClass("astro-code"));
        assert.equal(
          $(e).closest("pre").attr("data-language"),
          expected[i].language || "plaintext",
        );
        assert.ok(
          $(e).find(isDocs ? ".ec-line" : ".line").length > 0,
          "highlighted code lines",
        );
      });
      const selector = isDocs
        ? ".sl-markdown-content :header[id]"
        : ".article-body :header[id]";
      for (const h of $(selector).toArray()) {
        const id = $(h).attr("id");
        const anchor = isDocs
          ? $(h).parent().find(".sl-anchor-link")
          : $(h).find("[data-heading-anchor]");
        assert.equal(decodeURIComponent(anchor.attr("href")!), `#${id}`);
        assert.ok(
          $("starlight-toc a,.article-sidebar a")
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
      const docsPrefix = "/" + route.split("/")[1] + "/docs/";
      const links = $("#starlight__sidebar a[href]")
        .toArray()
        .map((element) => $(element).attr("href")!)
        .filter((href) => href.startsWith(docsPrefix));
      assert.deepEqual(
        new Set(links),
        new Set(contentRoutes.filter((path) => path.startsWith(docsPrefix))),
      );
      assert.equal(
        $("#starlight__sidebar a[aria-current=page]").attr("href"),
        route,
      );
      assert.equal($(".site-title").attr("href"), docsPrefix);
      assert.equal($(".site-title").text().trim(), "OpenCI Docs");
      if (route !== docsPrefix) {
        assert.equal(
          $(".lead").text(),
          $("meta[name=description]").attr("content"),
        );
      }
      for (const link of $(".pagination-links a").toArray()) {
        assert.ok($(link).attr("href")!.startsWith(docsPrefix));
      }
      assert.equal($("site-search #starlight__search").length, 1);
      assert.equal($("[data-pagefind-body]").length, 1);
      const translations = JSON.parse(
        $("site-search").attr("data-translations")!,
      );
      assert.equal(
        translations.placeholder,
        route.startsWith("/ja/") ? "検索" : "Search",
      );
      assert.ok(existsSync("dist/pagefind/pagefind.js"));
      assert.equal(
        $("a[href*='/edit/develop/']").attr("href"),
        "https://github.com/openci-org/openci/edit/develop/apps/website/" +
          contentFiles.get(route),
      );
    });
  }
}
for (const locale of ["en", "ja"] as const) {
  test(`${locale}: landing and Docs samples use highlighted, copyable code`, () => {
    const landing = pages.get(`/${locale}/`)!;
    for (const name of ["flutter", "android", "testflight"]) {
      const sample = landing(
        `#workflow-${name} pre.astro-code[data-language=dart]`,
      );
      assert.equal(sample.length, 1);
      assert.ok(sample.find("code .line").length > 1);
    }
    assert.match(
      landing("#workflow-flutter code").text(),
      /ci\.flutter\.unitTests\(/,
    );
    assert.match(
      landing("#workflow-android code").text(),
      /ci\.flutter\.buildAab\(/,
    );
    assert.match(
      landing("#workflow-testflight code").text(),
      /ci\.flutter\.deployIpaToTestFlight\(/,
    );
    assert.equal(landing(".example [data-blog-copy]").length, 3);
    assert.equal(
      landing('[role="tab"][aria-selected=true]').attr("aria-controls"),
      "workflow-flutter",
    );
    const docs = pages.get(`/${locale}/docs/`)!;
    const home = docs(".expressive-code pre[data-language=dart]");
    assert.equal(home.length, 1);
    assert.ok(home.find("code").text().includes("Future<void> main() async {"));
    assert.equal(
      home.closest(".expressive-code").find("button[title]").length,
      1,
    );
    const cli = pages.get(`/${locale}/docs/cli/`)!;
    const installLines = cli(".sl-markdown-content pre code")
      .first()
      .find(".ec-line .code")
      .map((_, line) => cli(line).text().trim())
      .get();
    assert.deepEqual(installLines, [
      "dart install openci_cli_plus",
      "openci --help",
    ]);
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
    assert.equal(
      $(".desktop-links [aria-current=page]").attr("href"),
      `/${locale}/blog/`,
    );
    const categories = $(".post-card")
      .toArray()
      .map((card) => $(card).attr("data-article-category"));
    assert.deepEqual(
      new Set(
        $("[data-category-filter]")
          .toArray()
          .map((button) => $(button).attr("data-category-filter")),
      ),
      new Set(["all", ...categories]),
    );
    for (const img of $(".post-cover img").toArray()) {
      assert.ok(existsSync("dist" + $(img).attr("src")));
    }
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
  test(`${locale}: per-minute pricing and language links are correct`, () => {
    const $ = pages.get(`/${locale}/`)!;
    const details = pages.get(`/${locale}/pricing/`)!;
    const pricing = details("#pricing");
    assert.equal(
      pricing.find(".cloud-plan h2 strong").text(),
      locale === "ja" ? "¥1" : "1¢",
    );
    assert.equal(
      details("h1 strong").text(),
      locale === "ja" ? "1分1円。" : "1 cent per minute.",
    );
    assert.equal(
      $("h1 strong").text(),
      locale === "ja" ? "1分1円で。" : "1 cent per minute.",
    );
    assert.equal($(".claim").attr("href"), `/${locale}/pricing/#comparison`);
    assert.match(
      $(".claim").text(),
      locale === "ja" ? /世界最安/ : /lowest-priced/,
    );
    assert.ok(
      $("#pricing a")
        .toArray()
        .some((a) => $(a).attr("href") === `/${locale}/pricing/`),
    );
    assert.deepEqual(
      $("#estimate option")
        .toArray()
        .map((e) => $(e).attr("value")),
      ["10", "100", "1000"],
    );
    assert.equal(
      $("#estimate output").text(),
      locale === "ja" ? "¥100" : "$1.00",
    );
    assert.equal(pricing.find("#minutes").attr("value"), "200");
    assert.equal(
      pricing.find("output").text(),
      locale === "ja" ? "¥200" : "$2.00",
    );
    for (const id of [
      "pricing",
      "features",
      "workflow",
      "get-started",
      "apis",
      "quickstart",
      "guides",
    ]) {
      assert.equal($("#" + id).length, 1);
    }
    const rates = pricing
      .find(".pricing-comparison td")
      .toArray()
      .map((cell) => $(cell).text());
    assert.deepEqual(
      rates,
      locale === "ja" ? ["US$0.0067", "US$0.062"] : ["1¢", "6.2¢"],
    );
    assert.match(
      pricing.find(".pricing-comparison caption").text(),
      locale === "ja" ? /150/ : /US cents/,
    );
    assert.ok(
      pricing
        .text()
        .includes(
          locale === "ja"
            ? "月締め時に記録した為替レート"
            : "exchange rate recorded when the billing month closes",
        ),
    );
    if (locale === "en") {
      assert.match(
        pricing.find("#faq").text(),
        /actual charges at ¥1 per minute/,
      );
      assert.match($("title").text(), /1 cent per minute/);
      assert.match(
        details("meta[name=description]").attr("content")!,
        /1 US cent per minute/,
      );
    }
    const [openci, github] = rates.map((rate) =>
      parseFloat(rate.replace("US$", "")),
    );
    const savings = Math.round((1 - openci / github) * 100);
    assert.ok(pricing.find(".pricing-savings").text().includes(`${savings}%`));
    assert.ok(pricing.find(".pricing-savings").text().includes("macOS"));
    assert.equal(
      pricing.find(".pricing-comparison-note a").first().attr("href"),
      "https://docs.github.com/en/billing/reference/actions-runner-pricing",
    );
    assert.ok(
      pricing
        .find(".pricing-comparison-note")
        .text()
        .includes(
          locale === "ja"
            ? "無料利用・割引を除く"
            : "Free usage and discounts excluded",
        ),
    );
    assert.deepEqual(
      pricing
        .find("#comparison .pricing-comparison-note")
        .last()
        .find("a")
        .toArray()
        .map((a) => details(a).text().trim()),
      ["GitHub Actions", "Codemagic", "Namespace"],
    );
    assert.equal(
      pricing.find(".cloud-plan .action").attr("href"),
      "https://dashboard.openci.org/",
    );
    assert.equal(
      pricing.find(".plans article").last().find("a").attr("href"),
      `/${locale}/docs/self-hosting/`,
    );
    assert.doesNotMatch(
      pricing.text(),
      /\b(?:Light|Pro)\b|600|6,000|168|月・チーム|month per team|no overage charges|追加の従量料金は発生しません/,
    );
    assert.equal($(".language-switcher a").length, 2);
    assert.equal(
      $(".language-switcher [aria-current=page]").attr("lang"),
      locale,
    );
  });
}
test("runtime estimates round monthly minutes once before formatting local prices", () => {
  assert.equal(formatRuntimeEstimate(0, "en"), "$0.00");
  assert.equal(formatRuntimeEstimate(0.5, "en"), "$0.01");
  assert.equal(formatRuntimeEstimate(100.1, "en"), "$1.01");
  assert.equal(formatRuntimeEstimate(100.1, "ja"), "¥101");
  assert.equal(formatRuntimeEstimate(123456, "en"), "$1,234.56");
  for (const minutes of [-1, NaN, Infinity, Number.MAX_SAFE_INTEGER + 1]) {
    assert.equal(formatRuntimeEstimate(minutes, "en"), "—");
  }
});
test("Japanese Markdown headings use Astro's generated IDs", () => {
  const $ = pages.get("/ja/docs/quickstart/")!;
  assert.deepEqual(
    $(".sl-markdown-content h2")
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
  for (const [route, $] of pages) {
    const styles = [
      $("style").text(),
      ...$("link[rel=stylesheet]")
        .toArray()
        .map((link) => read("dist" + $(link).attr("href"))),
    ].join("\n");
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
  ["/ja/", "#quickstart", true],
  ["/en/pricing/", "#comparison", true],
  ["/en/blog/v2-3-0/", "#article-heading", false],
] as const) {
  test(`${route}: language switching preserves queries and appropriate anchors`, () => {
    const location = new URL(
      "https://openci.org" + route + "?source=mail" + hash,
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
    assert.ok(links.length > 0);
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
test("translated articles and docs keep identical executable examples", () => {
  for (const [route, file] of contentFiles) {
    if (!route.startsWith("/en/")) continue;
    const translation = contentFiles.get(route.replace(/^\/en\//, "/ja/"));
    if (!translation) continue;
    assert.deepEqual(fences(read(file)), fences(read(translation)), file);
  }
});
test("root redirect and legacy hosting routes retain their destinations", () => {
  assert.ok(read("dist/index.html").includes("url=/en/"));
  const hosting = JSON.parse(read("firebase.json")).hosting;
  assert.equal(hosting.public, "build/hosting");
  const project = JSON.parse(read(".firebaserc")).targets["openci-b1b91"];
  assert.deepEqual(project.hosting[hosting.target], ["openci-b1b91"]);
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
