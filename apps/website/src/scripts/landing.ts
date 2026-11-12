for (const card of document.querySelectorAll<HTMLElement>("[data-estimate]")) {
  const input = card.querySelector<HTMLInputElement | HTMLSelectElement>(
    "input, select",
  )!;
  const output = card.querySelector<HTMLOutputElement>("output")!;
  const numbers = new Intl.NumberFormat(document.documentElement.lang);
  function calculate() {
    const minutes = Number(input.value);
    const billed = Math.ceil(minutes);
    output.value =
      input.value.trim() && minutes >= 0 && Number.isSafeInteger(billed)
        ? "¥" + numbers.format(billed)
        : "—";
  }
  input.addEventListener("input", calculate);
  input.addEventListener("change", calculate);
  calculate();
}

const menu = document.querySelector<HTMLDetailsElement>(".mobile-nav")!;
document.addEventListener("click", (event) => {
  if (
    event.target instanceof Element &&
    (!menu.contains(event.target) || event.target.closest("a"))
  )
    menu.open = false;
});
document.addEventListener("keydown", (event) => {
  if (event.key === "Escape" && menu.open) {
    menu.open = false;
    menu.querySelector("summary")?.focus();
  }
});
matchMedia("(min-width: 801px)").addEventListener("change", () => {
  menu.open = false;
});

const root = document.documentElement;
const controls = document.querySelector<HTMLElement>(".display-controls")!;
const themeButton = controls.querySelector<HTMLButtonElement>("[data-theme]")!;
const motionButton =
  controls.querySelector<HTMLButtonElement>("[data-motion]")!;
const systemDark = matchMedia("(prefers-color-scheme: dark)");
const systemStill = matchMedia("(prefers-reduced-motion: reduce)");
function preference(key: string, value?: string) {
  try {
    if (value !== undefined) localStorage.setItem("openci-" + key, value);
    return localStorage.getItem("openci-" + key);
  } catch {
    return null;
  }
}
let theme = preference("theme");
let pause = preference("paused") === "true";
function updateTheme() {
  const dark = theme ? theme === "dark" : systemDark.matches;
  root.dataset.theme = dark ? "dark" : "light";
  themeButton.setAttribute("aria-pressed", String(dark));
  themeButton.firstElementChild!.textContent = dark ? "☀" : "☾";
}
themeButton.addEventListener("click", () => {
  theme = root.dataset.theme === "dark" ? "light" : "dark";
  preference("theme", theme);
  updateTheme();
});
systemDark.addEventListener("change", updateTheme);
updateTheme();
controls.hidden = false;

const lake = document.querySelector<HTMLImageElement>(".lake-image");
const surface = document.querySelector<HTMLCanvasElement>(".lake-motion");
const brush = surface?.getContext("2d");
if (lake && surface && brush) {
  let visible = false;
  let frame = 0;
  let lastPaint = 0;
  const paint = (now: number) => {
    frame = requestAnimationFrame(paint);
    if (now - lastPaint < 85) return;
    lastPaint = now;
    const { width, height } = surface;
    // The canvas uses the source's coordinates. CSS applies the same cover crop to both layers.
    const shore = Math.floor(height * 0.69);
    brush.clearRect(0, shore, width, height - shore);
    for (let y = shore; y < height; y += 2) {
      const depth = (y - shore) / (height - shore);
      const offset = Math.round(Math.sin(y * 0.29 + now / 850) * 3 * depth);
      brush.drawImage(lake, 4 + offset, y, width - 8, 2, 4, y, width - 8, 2);
    }
  };
  const syncMotion = () => {
    const still = pause || systemStill.matches;
    motionButton.disabled = systemStill.matches;
    motionButton.setAttribute("aria-pressed", String(still));
    motionButton.firstElementChild!.textContent = still ? "▷" : "Ⅱ";
    cancelAnimationFrame(frame);
    surface.hidden = still;
    if (
      !still &&
      visible &&
      !document.hidden &&
      lake.complete &&
      lake.naturalWidth > 0
    )
      frame = requestAnimationFrame(paint);
  };
  surface.width = Number(lake.getAttribute("width"));
  surface.height = Number(lake.getAttribute("height"));
  new IntersectionObserver(([entry]) => {
    visible = entry!.isIntersecting;
    syncMotion();
  }).observe(lake);
  motionButton.addEventListener("click", () => {
    pause = !pause;
    preference("paused", String(pause));
    syncMotion();
  });
  lake.addEventListener("load", syncMotion);
  systemStill.addEventListener("change", syncMotion);
  document.addEventListener("visibilitychange", syncMotion);
  syncMotion();
} else {
  motionButton.hidden = true;
}
