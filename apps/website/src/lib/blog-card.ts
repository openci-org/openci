import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import CanvasKitInit from "canvaskit-wasm/full";
import type { Canvas, Image, Paragraph } from "canvaskit-wasm/full";
import type { Page } from "./content";
import type { Locale } from "./i18n";

const width = 1200;
const height = 630;
const photoWidth = 548;
const inset = 52;
const left = photoWidth + inset;
const textWidth = width - left - inset;
const footerRuleTop = 534;
const contentTop = 116;
const contentBottom = footerRuleTop - 20;

const skia = await CanvasKitInit();
async function loadFonts() {
  const files = [
    "public/fonts/lora.ttf",
    "public/fonts/geist.ttf",
    "src/assets/fonts/NotoSansJP.ttf",
  ];
  const data = await Promise.all(
    files.map(async (file) => Uint8Array.from(await readFile(file)).buffer),
  );
  const fonts = skia.FontMgr.FromData(...data);
  assert(fonts, "Could not load the OpenCI blog fonts");
  return fonts;
}

async function loadImage(path: string) {
  const image = skia.MakeImageFromEncoded(await readFile("public" + path));
  assert(image, `Cannot decode blog card image ${path}`);
  return image;
}
const [fontManager, logo] = await Promise.all([
  loadFonts(),
  loadImage("/favicon.png"),
]);

function drawCover(canvas: Canvas, image: Image) {
  const scale = Math.max(photoWidth / image.width(), height / image.height());
  const cropWidth = photoWidth / scale,
    cropHeight = height / scale;
  const crop = skia.XYWHRect(
    (image.width() - cropWidth) / 2,
    (image.height() - cropHeight) / 2,
    cropWidth,
    cropHeight,
  );
  canvas.drawImageRectCubic(
    image,
    crop,
    skia.XYWHRect(0, 0, photoWidth, height),
    1 / 3,
    1 / 3,
  );
}

function paragraph(value: string, family: string, size: number, color: string) {
  const style = new skia.ParagraphStyle({
    textStyle: {
      fontFamilies: [family, "Noto Sans JP"],
      fontSize: size,
      color: skia.parseColorString(color),
      heightMultiplier: 1.16,
    },
  });
  const builder = skia.ParagraphBuilder.Make(style, fontManager);
  builder.addText(value);
  const result = builder.build();
  builder.delete();
  result.layout(textWidth);
  return result;
}

// Keep each text block within its allotted height, including very long localized titles.
function drawText(
  canvas: Canvas,
  block: Paragraph,
  x: number,
  y: number,
  maxHeight: number,
) {
  const scale = Math.min(1, maxHeight / Math.max(1, block.getHeight()));
  canvas.save();
  canvas.translate(x, y);
  canvas.scale(scale, scale);
  canvas.drawParagraph(block, 0, 0);
  canvas.restore();
  block.delete();
}

export async function renderBlogCard(
  { title, description, category, date }: Page["data"],
  coverPath: string,
  locale: Locale,
  jpeg: boolean,
) {
  const cover = await loadImage(coverPath);
  const surface = skia.MakeSurface(width, height);
  try {
    assert(surface, "Could not create a blog card");
    const canvas = surface.getCanvas();
    canvas.clear(skia.parseColorString("#faf9f6"));
    drawCover(canvas, cover);
    canvas.drawImageRectCubic(
      logo,
      skia.XYWHRect(0, 0, logo.width(), logo.height()),
      skia.XYWHRect(left, inset, 40, 40),
      1 / 3,
      1 / 3,
    );
    const brand = paragraph("OpenCI Blog", "Geist", 28, "#20221f");
    drawText(
      canvas,
      brand,
      left + 54,
      inset + (40 - brand.getHeight()) / 2,
      40,
    );

    const heading = paragraph(
      title,
      locale === "ja" ? "Noto Sans JP" : "Lora",
      48,
      "#20221f",
    );
    const summary = paragraph(
      description,
      locale === "ja" ? "Noto Sans JP" : "Geist",
      23,
      "#545853",
    );
    const headingHeight = Math.min(heading.getHeight(), 205);
    const summaryHeight = Math.min(summary.getHeight(), 150);
    const gap = 20;
    const top =
      (contentTop + contentBottom - headingHeight - summaryHeight - gap) / 2;
    drawText(canvas, heading, left, top, headingHeight);
    drawText(canvas, summary, left, top + headingHeight + gap, summaryHeight);

    const rule = new skia.Paint();
    rule.setColor(skia.parseColorString("#d4d5ce"));
    canvas.drawRect(skia.XYWHRect(left, footerRuleTop, textWidth, 1), rule);
    rule.delete();
    const details = [category, date?.replaceAll("-", "."), jpeg && "openci.org"]
      .filter(Boolean)
      .join("   /   ");
    drawText(
      canvas,
      paragraph(details, "Geist", 21, "#39468a"),
      left,
      footerRuleTop + 16,
      36,
    );
    const image = surface.makeImageSnapshot();
    const bytes = image.encodeToBytes(
      jpeg ? skia.ImageFormat.JPEG : skia.ImageFormat.PNG,
      90,
    );
    image.delete();
    if (!bytes) throw new Error("Could not encode a blog card");
    return bytes;
  } finally {
    cover.delete();
    surface?.dispose();
  }
}
