"use client";
import Image from "next/image";
import lakePhoto from "../../../website/public/images/blog/blanca-lake.jpg";
import { useEffect, useRef } from "react";

// A short palette gives the forest, granite and water distinct pixel tones.
const palette = [
  [21, 38, 33],
  [35, 55, 40],
  [55, 75, 45],
  [77, 97, 56],
  [101, 121, 65],
  [130, 146, 85],
  [158, 169, 111],
  [189, 195, 150],
  [215, 217, 180],
  [240, 237, 207],
  [253, 249, 229],
  [50, 64, 66],
  [76, 89, 90],
  [101, 117, 117],
  [126, 143, 142],
  [151, 166, 165],
  [179, 191, 190],
  [205, 216, 212],
  [229, 234, 226],
  [61, 90, 107],
  [82, 114, 136],
  [104, 144, 165],
  [133, 174, 190],
  [168, 202, 210],
  [21, 63, 66],
  [24, 84, 83],
  [32, 105, 102],
  [44, 126, 119],
  [62, 150, 140],
  [85, 174, 157],
  [122, 197, 176],
  [164, 216, 194],
  [207, 235, 211],
];
const dither = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5];

// Work in photo coordinates so the shore and its reflection share the mobile crop.
export function Landscape() {
  const photo = useRef<HTMLImageElement>(null);
  const canvas = useRef<HTMLCanvasElement>(null);
  useEffect(() => {
    const img = photo.current!,
      surface = canvas.current!;
    const brush = surface.getContext("2d");
    const texture = document.createElement("canvas");
    const ink = texture.getContext("2d");
    if (!brush || !ink) return;
    const width = surface.width,
      height = surface.height;
    texture.width = width;
    texture.height = height;
    const shore = Math.round(height * 0.69);
    let frame = 0,
      last = 0,
      ready = false,
      visible = false;
    const still = () => document.documentElement.dataset.motion === "paused";
    const draw = (time: number) => {
      brush.drawImage(texture, 0, 0);
      for (let y = shore; y < height; y += 2) {
        const depth = (y - shore) / (height - shore);
        const shift = Math.round(
          depth * (Math.sin(y * 0.19 - time / 730) * 3 + Math.sin(y * 0.05 + time / 1300) * 2),
        );
        brush.drawImage(texture, 5 + shift, y, width - 10, 2, 5, y, width - 10, 2);
      }
      for (let i = 0; i < 12; i++) {
        const depth = ((i * 41 + 11) % 93) / 100;
        const glow = (1 + Math.sin(time / 680 + i * 3.7)) / 2;
        brush.fillStyle = `rgba(226,255,237,${glow ** 4 * 0.68})`;
        brush.fillRect(
          Math.floor((i * 103 + time * 0.004) % width),
          shore + Math.floor(depth * (height - shore)),
          1 + Math.round(depth * 4),
          1,
        );
      }
    };
    const tick = (now: number) => {
      if (now - last >= 1000 / 24) {
        draw(now);
        last = now;
      }
      frame = requestAnimationFrame(tick);
    };
    const sync = () => {
      cancelAnimationFrame(frame);
      if (!ready) return;
      if (!visible || document.hidden || still()) {
        draw(0);
        return;
      }
      frame = requestAnimationFrame(tick);
    };
    const prepare = () => {
      if (ready || !img.naturalWidth) return;
      ink.drawImage(img, 0, 0, width, height);
      const pixels = ink.getImageData(0, 0, width, height);
      for (let y = 0; y < height; y++) {
        const water = Math.min(1, Math.max(0, (y - shore) / 10));
        for (let x = 0; x < width; x++) {
          const i = (y * width + x) * 4;
          const red = pixels.data[i],
            green = pixels.data[i + 1],
            blue = pixels.data[i + 2];
          const light = 0.21 * red + 0.72 * green + 0.07 * blue;
          const grain = (dither[(y % 4) * 4 + (x % 4)] - 7.5) * 1.8;
          const r = red + (red - light) * 0.26 + grain - water * light * 0.22;
          const g = green + (green - light) * 0.2 + grain + water * 12;
          const b = blue + (blue - light) * 0.18 + grain + water * (light * 0.26 + 9);
          let best = palette[0],
            distance = Infinity;
          for (const color of palette) {
            const error =
              0.3 * (r - color[0]) ** 2 + 0.5 * (g - color[1]) ** 2 + 0.2 * (b - color[2]) ** 2;
            if (error < distance) {
              distance = error;
              best = color;
            }
          }
          pixels.data[i] = best[0];
          pixels.data[i + 1] = best[1];
          pixels.data[i + 2] = best[2];
        }
      }
      ink.putImageData(pixels, 0, 0);
      ready = true;
      draw(0);
      sync();
    };
    const observer = new IntersectionObserver(([entry]) => {
      visible = entry.isIntersecting;
      sync();
    });
    const motion = new MutationObserver(sync);
    observer.observe(surface);
    motion.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ["data-motion"],
    });
    document.addEventListener("visibilitychange", sync);
    img.addEventListener("load", prepare);
    if (img.complete) prepare();
    return () => {
      cancelAnimationFrame(frame);
      observer.disconnect();
      motion.disconnect();
      document.removeEventListener("visibilitychange", sync);
      img.removeEventListener("load", prepare);
    };
  }, []);
  return (
    <>
      <Image
        ref={photo}
        className="lake-image"
        src={lakePhoto}
        width={1100}
        height={600}
        alt=""
        preload
      />
      <canvas ref={canvas} width={550} height={300} className="lake-motion" aria-hidden="true" />
    </>
  );
}
